# 18. Launcher, clipboard, power and toasts

The center island owns the panels that don't belong to anything else (chapter 10). This chapter covers three of them, the launcher, the clipboard and the power menu, plus the toasts that appear under the workspaces. The cheatsheet was chapter 9 and the screenshot panel is chapter 19.

The launcher and clipboard share one service, [`services/Launcher.qml`](../../config/quickshell/services/Launcher.qml), with a `mode` of `"launcher"`, `"clipboard"` or `""`. They're two views of "a search box that does something with the result", and they toggle each other: pressing `Mod+Y` while the launcher is open switches the same island to the clipboard.

## The launcher

`Alt+Space` opens it. [`LauncherPanel.qml`](../../config/quickshell/modules/bar/LauncherPanel.qml) is a `TextField` over a `MenuList`. The text field keeps focus the whole time and its `navigate` signal moves the selection (chapter 12), so you type and press `↓` without ever leaving the box.

### Finding apps

quickshell reads the system's `.desktop` files into `DesktopEntries.applications`. The launcher scores each entry against what you typed:

```qml
  function scoreText(text, q) {
    if (!text)
      return 0;
    const t = text.toLowerCase();
    if (t === q)
      return 120;
    if (t.startsWith(q))
      return 100;
    if (t.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
      return 80;
    if (t.includes(q))
      return 60;
    let i = 0;
    for (const c of t) {
      if (c === q[i])
        i++;
      if (i === q.length)
        return 20;
    }
    return 0;
  }
```

[`services/Launcher.qml:86-106`](../../config/quickshell/services/Launcher.qml#L86-L106)

An exact match beats a prefix, a prefix beats the start of a later word ("code" in "Visual Studio Code"), which beats appearing anywhere, which beats having the letters in order ("ffx" for Firefox). The app's name counts fully. Its generic name ("Web Browser"), keywords and id count for less.

Then usage is added on top:

```qml
      list.push({
        entry: entry,
        score: score + Math.log(used + 1) * 12
      });
```

[`services/Launcher.qml:124-127`](../../config/quickshell/services/Launcher.qml#L124-L127)

Every launch is counted in `~/.local/state/yurice/launcher.json`. The bonus is logarithmic, so an app you open daily rises above one you opened once, but it can't beat a much better text match. With an empty query, the list is just your apps by how often you use them.

App icons go through `Quickshell.iconPath`, which looks them up in your icon theme. Some apps only install their icon into the `hicolor` fallback theme, which icon themes don't always search. So when the launcher opens, it scans every `icons/hicolor` folder in your data directories once and keeps the largest icon for each name, and those are tried before the theme lookup.

### The calculator

If what you type looks like math, a result row appears at the top. `isMath` decides that with a few rules: starting with `=`, digits with an operator, a function call like `sqrt(2)`, or a unit conversion like `5 km to mi`. The calculation itself is [qalculate](https://qalculate.github.io), run as `qalc -t`:

```qml
  Timer {
    id: calcDebounce
    interval: 150
    onTriggered: {
      calc.command = ["qalc", "-t", "--", root.calcQuery];
      calc.running = true;
    }
  }
```

[`services/Launcher.qml:226-233`](../../config/quickshell/services/Launcher.qml#L226-L233)

The debounce waits 150 ms after your last key, so typing `1234*5678` runs qalc once and not nine times. qalc handles units, currencies, percentages and much more. The result is hidden if qalc just echoes the input back or prints an error. `Enter` on the result row copies it with `wl-copy` and closes the launcher.

## The clipboard

`Mod+Y` opens the clipboard history. The history itself is kept by [cliphist](https://github.com/sentriz/cliphist), fed by two user services the installer sets up:

```ini
ExecStart=wl-paste --watch cliphist store
ExecStart=wl-paste --type image --watch cliphist store
```

[`dist/systemd/yurice-cliphist.service`](../../dist/systemd/yurice-cliphist.service), [`yurice-cliphist-images.service`](../../dist/systemd/yurice-cliphist-images.service)

`wl-paste --watch` runs a command every time the clipboard changes, so everything you copy, text and images, is stored. The shell only reads the history when the panel opens, with `cliphist list`. Each line is an id, a tab and a preview. Images have previews like `[[ binary data 32 KiB png 800x600 ]]`, which the service recognizes and turns into image rows. Their thumbnails are decoded with `cliphist decode` into `~/.cache/yurice/clip/` the first time each one is shown, one process per image.

Typing filters the text entries. `Shift+Delete` removes the selected entry from cliphist.

### Pasting

Picking an entry doesn't just copy it, it pastes it into the window you were in. [`scripts/clip-paste.sh`](../../config/quickshell/scripts/clip-paste.sh) does that in three steps:

```sh
cliphist decode "$id" | wl-copy || exit 1
sleep 0.25
app=$(niri msg --json focused-window | grep -o '"app_id":"[^"]*"' | cut -d'"' -f4)
for term in "$@"; do
  if [ "$app" = "$term" ]; then
    exec wtype -M ctrl -M shift v -m shift -m ctrl
  fi
done
exec wtype -M ctrl v -m ctrl
```

It puts the entry on the clipboard, waits a quarter second for the panel to close and focus to return to your window, then types the paste shortcut with `wtype`. Terminals use `Ctrl+Shift+V` instead of `Ctrl+V`, so the script asks niri which app is focused and checks it against a list of terminal app ids (kitty, foot, alacritty, wezterm and ghostty) passed in from the service.

## The power menu

`Mod+Q` opens [`PowerPanel.qml`](../../config/quickshell/modules/bar/PowerPanel.qml): power off, reboot, log out and suspend in a row, with suspend selected. Unlike other panels, it moves its own selection with `h`, `l`, the arrows and `Tab` (chapter 12), because it's a single row of four big buttons.

The first three ask for confirmation, and they do it without a dialog:

```qml
  function activate(index) {
    const action = actions[index];
    selected = index;
    if (action.confirm && armed !== action.id) {
      armed = action.id;
      disarm.restart();
      return;
    }
    armed = "";
    if (action.id === "suspend")
      SessionLock.lockAndSuspend();
    else if (action.id === "logout")
      Session.logout();
    else
      Session.run(action.id);
  }
```

[`modules/bar/PowerPanel.qml:45-60`](../../config/quickshell/modules/bar/PowerPanel.qml#L45-L60)

The first press "arms" the button: it turns the error color and its label changes to "Press again". The second press within three seconds runs it. Moving to another button disarms it. So `Mod+Q`, `←`, `Enter`, `Enter` reboots, and a stray `Enter` never does.

Suspend locks the screen first and only suspends once the lock is confirmed (chapter 20). Log out plays the outro from chapter 17 and then quits niri. Power off and reboot go through [`Session.run`](../../config/quickshell/services/Session.qml), which calls `systemctl`. On machines with UEFI, the lock screen's power menu also offers rebooting into firmware setup.

Caffeine needs one more step before any kind of sleep. Its `systemd-inhibit` lock blocks sleep, which is the point while you're working, but it would also block a suspend you asked for. So `Session.run` first asks caffeine to let go:

```qml
    if (sleepActions.includes(action))
      Caffeine.release(start);
    else
      start();
```

[`services/Session.qml:42-45`](../../config/quickshell/services/Session.qml#L42-L45)

`release` stops the inhibitor process, waits until it has actually exited, then runs the callback. After resume, caffeine takes the lock again by itself.

## Toasts

Toasts are the small cards that drop in under the workspaces. They come from two places: other apps sending desktop notifications, and the shell telling you something (Caps Lock, keyboard layout, a saved screenshot).

### Being the notification server

On Linux, apps send notifications over D-Bus to whatever program owns the `org.freedesktop.Notifications` name. quickshell can be that program:

```qml
  NotificationServer {
    keepOnReload: true
    actionsSupported: true
    imageSupported: true
    bodySupported: true
    bodyMarkupSupported: false
    persistenceSupported: true
    onNotification: n => {
      n.tracked = true;
      root.addNotification(n);
    }
  }
```

[`services/Notifications.qml:158-169`](../../config/quickshell/services/Notifications.qml#L158-L169)

`tracked = true` tells quickshell to keep the notification alive after the handler returns. `keepOnReload` keeps it across a shell reload. The flags tell apps what the server supports, so they can send action buttons and images, and don't send HTML.

[`services/Notifications.qml`](../../config/quickshell/services/Notifications.qml) keeps the visible toasts in a `ListModel`, newest first, at most three. A fourth pushes out the oldest. An app that updates a notification it already sent (a download's progress, say) updates the existing toast instead of adding one.

### The shell's own toasts

`notifyLocal(key, symbol, summary, body, timeout)` adds a toast with a Material Symbols icon instead of an app icon. The key makes repeats replace each other:

```qml
    const i = indexOfKey(key);
    if (i >= 0) {
      model.set(i, Object.assign(entry, {
        generation: model.get(i).generation + 1
      }));
      return;
    }
```

[`services/Notifications.qml:108-114`](../../config/quickshell/services/Notifications.qml#L108-L114)

Press Caps Lock five times and you see one toast that keeps changing between "Caps Lock on" and "Caps Lock off", not five. `generation` goes up with every update, and the toast restarts its timer when it does:

```qml
    onGenerationChanged: if (timer.running)
      timer.restart()

    Timer {
      id: timer
      interval: toast.timeout
      running: toast.timeout > 0 && !hover.hovered
      onTriggered: Notifications.close(toast.uid, false)
    }
```

[`modules/bar/Toasts.qml:93-101`](../../config/quickshell/modules/bar/Toasts.qml#L93-L101)

The timer is bound to not being hovered, so a toast stays as long as your mouse is on it. Critical notifications have a timeout of 0 and stay until you close them.

### Drawing them

[`modules/bar/Toasts.qml`](../../config/quickshell/modules/bar/Toasts.qml) is a `ListView` on the model, in the bar window under the workspaces, and only on the monitor you're using. The `ListView`'s `add`, `remove` and `displaced` transitions fade and scale toasts in and out and slide the others along, the same tool as the workspace dots in chapter 13. The bar's input mask includes the toasts (chapter 10), so they're clickable. A left click runs the notification's default action, a right click dismisses it, and action buttons appear under the text when the app sent any.

Next is the last panel in the center island, which takes over the whole screen.
