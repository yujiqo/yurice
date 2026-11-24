# 20. Lock screen, greeter and session

The lock screen and the login screen look the same on purpose: your wallpaper, your avatar in the middle, your name under it, and a password field that opens when you press `Enter`, `Space` or click. They're built from one shared component. The difference is who checks the password. The lock screen asks PAM directly. The login screen asks greetd, which then starts your session.

This is also the part of the shell where a bug costs the most. A broken panel is annoying. A broken lock screen either leaves your machine open or locks you out. A lot of this chapter is about what happens when something goes wrong.

## The shared face

[`modules/lock/LockSurface.qml`](../../config/quickshell/modules/lock/LockSurface.qml) draws the screen and knows nothing about authentication. It takes the wallpaper, avatar, user name, error text and a few flags as properties, and reports what you do as signals: `promptRequested`, `submitted(password)`, `powerRequested(action)`, `userSwitchRequested(delta)`. The lock screen and the greeter each wire it to their own service.

Everything in it is driven by one number, `reveal`, from 0 to 1:

```qml
  readonly property real lockScale: 1 + Theme.lockZoom * (1 - reveal)
```

[`modules/lock/LockSurface.qml:25`](../../config/quickshell/modules/lock/LockSurface.qml#L25)

The wallpaper, avatar and name fade in with `reveal` and settle from 125% to 100% scale. The pattern is chapter 5's, one number and everything derived from it, just with a fixed-length `NumberAnimation` of 550 ms instead of a spring, since locking is never interrupted halfway.

The password field sits in a `Collapse` and only opens on one screen, the one where you pressed a key or clicked. Below it, reboot and power off (and firmware setup on UEFI machines) use the same press-twice arming as the power menu in chapter 18.

## Locking

Wayland has a protocol made for lock screens, `ext-session-lock`. A client asks the compositor to lock, and from then on the compositor shows only that client's lock surfaces and sends input only to them. If the client crashes, the screen stays locked and shows a blank color. The compositor guarantees it, not the client. quickshell exposes this as `WlSessionLock`:

```qml
  WlSessionLock {
    locked: SessionLock.sessionLocked
    onSecureChanged: SessionLock.setSecured(secure)

    WlSessionLockSurface {
      id: surface
      color: Theme.scrim

      LockSurface {
        ...
        snapshot: SessionLock.snapshots[surface.screen?.name] ?? ""
        reveal: SessionLock.reveal
        interactive: SessionLock.phase === "locked"
        ...
        onSubmitted: password => SessionLock.submit(password)
      }
    }
  }
```

[`modules/lock/LockScreen.qml`](../../config/quickshell/modules/lock/LockScreen.qml)

`secure` becomes true when the compositor confirms the lock is in place. Until then, the service treats the screen as not locked yet.

### The phases

[`services/SessionLock.qml`](../../config/quickshell/services/SessionLock.qml) moves through named phases: `idle`, `settling`, `capturing`, `locking`, `locked`, `unlocking`, and `relocking` after a restart. Every function checks the phase first, so pressing the lock key twice, or the idle timer firing while you lock by hand, does nothing.

```qml
  function lock() {
    if (phase !== "idle")
      return;
    marker.setText("locked");
    const overlayOpen = Wallpapers.pickerOpen || Panels.isOpen || Session.isOpen || Launcher.isOpen;
    Wallpapers.pickerOpen = false;
    Panels.close();
    Session.close();
    Launcher.close();
    if (overlayOpen) {
      phase = "settling";
      settleDelay.restart();
    } else {
      startCapture();
    }
  }
```

[`services/SessionLock.qml:28-43`](../../config/quickshell/services/SessionLock.qml#L28-L43)

Locking starts by closing any open panel, launcher, power menu or picker, and waiting 450 ms for them to animate away if there were any. That's because the next step takes a picture of your screen.

### The transition

[`LockSnapshot.qml`](../../config/quickshell/modules/lock/LockSnapshot.qml) captures every screen with a `ScreencopyView`, the same tool as screenshots (chapter 19), and saves each capture with `grabToImage`. The lock surface then shows your desktop as it was, blurring and shrinking away while the wallpaper and avatar zoom in on top:

```qml
  Blur {
    anchors.fill: parent
    source: snapshotImage
    visible: root.reveal < 1 && snapshotImage.status === Image.Ready
    amount: root.reveal
    opacity: 1 - root.reveal
    scale: 1 - Theme.lockZoom * root.reveal
  }
```

[`modules/lock/LockSurface.qml:168-175`](../../config/quickshell/modules/lock/LockSurface.qml#L168-L175)

This is why the panels have to close first. The snapshot is what you see at the start of the animation, and a half-closed panel frozen in it would look wrong.

The animation only starts when three things are true: the snapshot exists (or 500 ms have passed), every screen's lock surface has loaded its wallpaper, and the compositor has confirmed the lock. Each step has a timeout so a slow screen can't hold things up forever. While the animation plays, the session is already locked. The desktop you see shrinking away is only a picture of it.

### Checking the password

Passwords go to PAM, the system's authentication library, through quickshell's `PamContext`:

```qml
  PamContext {
    id: pam
    config: "login"
    onPamMessage: {
      if (responseRequired)
        respond(root.pendingPassword);
    }
    onCompleted: result => {
      if (result === PamResult.Success)
        root.beginUnlock();
      else
        root.failAuth("Wrong password");
    }
    onError: root.failAuth("Can't check the password right now")
  }
```

[`services/SessionLock.qml:230-244`](../../config/quickshell/services/SessionLock.qml#L230-L244)

It uses the system's `login` PAM config, the same rules as logging in on a console. `submit` stores the password, starts PAM, and answers PAM's prompt with it. The password is cleared from the service as soon as PAM is done, whether it succeeded or not. A 30 second timeout aborts a PAM conversation that never finishes.

Unlocking plays the reveal backwards, then sets `locked` to false, which ends the session lock.

### Locking before sleep

When the laptop suspends, the lock has to be in place before the system sleeps, or the screen will briefly show your desktop when you open the lid. systemd has a mechanism for this, delay inhibitors:

```qml
  Process {
    running: !(root.preparingForSleep && root.secured && root.phase === "locked")
    command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=yurice", "--why=Lock the screen before sleep", "sleep", "infinity"]
  }
```

[`services/SessionLock.qml:254-257`](../../config/quickshell/services/SessionLock.qml#L254-L257)

A delay inhibitor tells logind "wait for me before sleeping", for up to a few seconds. Another process watches for logind's `PrepareForSleep` signal with `busctl wait`. When it arrives, the service locks right away and skips the animation. Once the lock is confirmed, the binding above becomes false, the inhibitor process ends, and logind lets the system sleep. This is the "process as a state" pattern from chapter 7, the same as caffeine.

Suspend from the power menu goes the other way: `lockAndSuspend()` locks first and only calls `systemctl suspend` once the phase is `locked` and the lock is confirmed.

### When the shell crashes

A crash while locked leaves the compositor showing a blank screen, safely locked but with no way to type a password. Two things get you out of it.

First, the service writes `locked` to a marker file in `$XDG_RUNTIME_DIR` when it locks, and clears it when it unlocks. When the shell starts and finds the marker, it locks again immediately. So restarting the shell, for example from a TTY, brings back a working lock screen.

Second, if the shell thinks it's locked but the compositor hasn't confirmed the lock within 8 seconds, something is wrong with the lock client itself, and the service runs [`scripts/recover-session.sh`](../../config/quickshell/scripts/recover-session.sh). The script finds the running niri session, kills every quickshell instance (gently first, then with `kill -9`), and starts a fresh one, which relocks from the marker. [TROUBLESHOOTING](../TROUBLESHOOTING.md) shows how to run it by hand from a TTY.

`shell.qml` also turns off hot reload while locked (chapter 2), so saving a QML file can't restart the shell under your lock screen.

## The greeter

The login screen is quickshell too, started by greetd. greetd is a small login daemon. It runs a greeter program as a dedicated user, and the greeter talks to greetd over a socket to log someone in.

### How it starts

The greeter can't use your config, since it runs before anyone is logged in, as the `greeter` user. So the installer copies the quickshell folder to a system location and sets up a minimal niri just for the login screen:

```kdl
hotkey-overlay {
  skip-at-startup
}

layout {
  background-color "#000000"
}
...
spawn-at-startup "@greeterStart@"

binds {
  Ctrl+Alt+Delete { quit skip-confirmation=true; }
}
```

[`dist/greeter/niri.kdl`](../../dist/greeter/niri.kdl)

greetd runs niri with this config, and niri runs [`dist/greeter/start.sh`](../../dist/greeter/start.sh):

```sh
if ! qs -p "@greeterQml@"; then
  kitty agreety --cmd niri-session
fi
niri msg action quit --skip-confirmation
```

It starts quickshell with [`greeter.qml`](../../config/quickshell/greeter.qml) as the entry point instead of `shell.qml`. If quickshell fails, it falls back to `agreety`, greetd's plain text login, in a kitty window, so a broken greeter never locks you out of your own machine. Either way, niri quits when the greeter is done and greetd moves on to your session.

On NixOS the module does the same setup with Nix (chapter 23), and `greeter.niriExtraConfig` lets you add to the greeter's niri config, for example monitor layout. On other distros, `/etc/yurice/greeter-local.kdl` is included for the same purpose.

### Who's logging in

[`services/GreeterSession.qml`](../../config/quickshell/services/GreeterSession.qml) reads the user list straight from `/etc/passwd`:

```qml
  readonly property var users: {
    const list = [];
    for (const line of passwd.text().split("\n")) {
      const fields = line.split(":");
      const uid = parseInt(fields[2]);
      if (fields.length < 7 || uid < 1000 || uid >= 60000 || /(nologin|false)$/.test(fields[6]))
        continue;
      list.push(fields[0]);
    }
    return list.sort();
  }
```

[`services/GreeterSession.qml:27-37`](../../config/quickshell/services/GreeterSession.qml#L27-L37)

Real users have ids from 1000 up and a real login shell. System accounts are skipped. The last user who logged in is remembered in `/var/lib/yurice/greeter/last-user` and selected first. With more than one user, arrows appear beside the name, and `h`/`l` or `←`/`→` switch users with the reveal animation played out and back in.

Each user's look comes from the files their own session published (chapter 17): `/var/lib/yurice/users/<name>/wallpaper.jpg`, `avatar.jpg` and `colors.json`. The greeter points `Theme.paletteFile` at that `colors.json`, so the login screen is in your colors, and switching users switches the whole palette.

### Talking to greetd

quickshell's `Greetd` type speaks greetd's protocol. Logging in is a short conversation:

1. `Greetd.createSession(userName)` starts a login for that user.
2. greetd forwards PAM's prompts as `authMessage`. The first prompt that needs an answer gets the password you typed.
3. If PAM asks for something else after that, like a one-time code, the password field's placeholder changes to PAM's message and the next thing you type answers it.
4. On success, greetd sends `readyToLaunch`.

```qml
    function onReadyToLaunch() {
      lastUser.setText(root.userName);
      root.authenticating = false;
      root.promptOpen = false;
      root.phase = "leaving";
      root.animate(0);
    }
```

[`services/GreeterSession.qml:150-156`](../../config/quickshell/services/GreeterSession.qml#L150-L156)

The greeter remembers the user, plays the reveal backwards, and when the animation finishes, calls `Greetd.launch` with the session command. That's [`scripts/start-session.sh`](../../config/quickshell/scripts/start-session.sh) running `niri-session`, or whatever `$YURICE_SESSION` says. The script clears the console first, so you don't see a flash of text between the greeter and your desktop. Your session then starts with the intro from chapter 17.

## Logging out

Logging out is the shortest path of all: `Session.logout()` fades a scrim over every screen (the outro from chapter 17), and when it's fully dark, runs `niri msg action quit --skip-confirmation`. niri exits, greetd sees the session end, and starts the greeter again.

That's the end of Part IV. The shell is complete. Part V is about the rest of the desktop that yurice configures: niri itself and the terminal.
