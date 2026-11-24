# 7. Services

Part I built everything that draws our shell, but panels are useless without information to show. This chapter is about the other half of the shell: services, the singletons in [`services/`](../../config/quickshell/services) that find out what the system is doing and offer ways to change it.

## What a service is

A service is a singleton (chapter 2) with three kinds of members:

- readonly properties that describe the current state: `Battery.percent`, `Audio.muted`, `Network.wifiSsid`
- functions that change it: `Audio.setVolume(v)`, `Caffeine.toggle()`
- sometimes signals for one-off moments that aren't state: `Niri.layoutSwitched(index)`

Modules only read the properties and call the functions. They never run commands, read files or open sockets themselves. When the battery panel shows `Battery.percent + "%"`, it has no idea where that number came from, and it doesn't need to.

Here's the top of [`services/Battery.qml`](../../config/quickshell/services/Battery.qml):

```qml
Singleton {
  id: root

  readonly property var display: UPower.displayDevice
  readonly property bool available: UPower.devices.values.some(d => d.isLaptopBattery)
  readonly property var device: UPower.devices.values.find(d => d.isLaptopBattery) ?? display
  ...
  readonly property int percent: Math.round(display.percentage * 100)
  readonly property bool charging: display.state === UPowerDeviceState.Charging
  readonly property bool full: display.state === UPowerDeviceState.FullyCharged
  readonly property bool plugged: !UPower.onBattery || charging || full
```

[`services/Battery.qml:13-21`](../../config/quickshell/services/Battery.qml#L13-L21)

Everything is a binding. There's no "update" function anywhere. When UPower reports a new percentage, `percent` changes, then `icon`, `color` and `status` (which are built from it), and then every panel that shows them.

A service is also where the meaning lives. The raw data says `state === Charging`. The service turns that into `"Full in 1h 20m"`, the right icon and the right color, once. Every module that shows battery info gets the same words.

## Four ways to know things

Every service gets its information in one of four ways. They're listed from most preferred to least.

### 1. quickshell's built-in services

quickshell ships modules that already talk to the common desktop daemons:

| Import                         | Talks to                 | Used by                                     |
| ------------------------------ | ------------------------ | ------------------------------------------- |
| `Quickshell.Services.UPower`   | UPower (battery, power)  | `Battery`                                   |
| `Quickshell.Services.Pipewire` | PipeWire (audio)         | `Audio`                                     |
| `Quickshell.Services.Mpris`    | media players over D-Bus | `Media`                                     |
| `Quickshell.Networking`        | NetworkManager           | `Network`                                   |
| `Quickshell.Bluetooth`         | BlueZ                    | the connectivity island and panel, directly |

When one of these exists, use it. It's event-driven, so it costs nothing while nothing changes, and it's already typed. Here's the whole audio service:

```qml
Singleton {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: !!sink?.audio
  readonly property bool muted: sink?.audio?.muted ?? false
  readonly property real volume: sink?.audio?.volume ?? 0
  readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)
  ...
  function setVolume(value) {
    if (ready) {
      const v = Math.max(0, Math.min(1, value));
      sink.audio.muted = v < 0.005;
      sink.audio.volume = v;
    }
  }
  ...
  PwObjectTracker {
    objects: [root.sink]
  }
}
```

[`services/Audio.qml`](../../config/quickshell/services/Audio.qml)

`?.` and `??` are everywhere. At startup there may be no default sink yet, and a headless test machine may have no PipeWire at all. A service must never throw because some hardware is missing. It reports a sensible empty value (`0`, `false`, `""`) and an `available` or `ready` flag, and the modules hide or dim themselves.

`PwObjectTracker` tells quickshell to keep the sink's live properties up to date. Without it, PipeWire objects are only partly loaded and `volume` never changes.

### 2. Files

Linux exposes a lot as plain files under `/sys`. `FileView` reads a file, and with `watchChanges` it re-reads it when it changes:

```qml
  FileView {
    id: curFile
    path: root.backlightDir ? root.backlightDir + "/actual_brightness" : ""
    watchChanges: true
    onFileChanged: reload()
  }
```

[`services/Brightness.qml:38-43`](../../config/quickshell/services/Brightness.qml#L38-L43)

and the service turns the text into a number with a binding:

```qml
  readonly property int percent: Math.round(parseInt(curFile.text()) / parseInt(maxFile.text()) * 100) || 0
```

Battery reads its extra details (design capacity, cycle count, charge limit) the same way, from `/sys/class/power_supply/…`. These files may not exist on every laptop, so they use `printErrors: false`, and the properties fall back to `-1`. That's why the battery panel's "Cycles" row has `visible: Battery.cycles >= 0`.

Not every sysfs file sends change notifications. The Caps Lock LED doesn't, so [`Keyboard.qml`](../../config/quickshell/services/Keyboard.qml) re-reads it on a 150 ms timer.

### 3. Processes

When there's no daemon to ask and no file to read, run a command. `Process` runs one, and `StdioCollector` hands you its output when it finishes:

```qml
  Process {
    running: true
    command: ["sh", "-c", "ls -d /sys/class/backlight/* 2>/dev/null | head -n 1"]
    stdout: StdioCollector {
      onStreamFinished: root.backlightDir = text.trim()
    }
  }
```

[`services/Brightness.qml:56-62`](../../config/quickshell/services/Brightness.qml#L56-L62)

That one runs once, at startup, to find the backlight folder. Processes show up in a few more shapes.

#### Writing, with a queue

Changing brightness runs `brightnessctl`. If you drag the slider, you'd start dozens of them at once. So the service runs one at a time and keeps only the latest request waiting:

```qml
  function run(arg) {
    if (writer.running) {
      pending = arg;
      return;
    }
    writer.command = ["brightnessctl", "-c", "backlight", "--min-value=1%", "-q", "s", arg];
    writer.running = true;
  }
  ...
  Process {
    id: writer
    onExited: {
      if (root.pending !== "") {
        const arg = root.pending;
        root.pending = "";
        root.run(arg);
      }
    }
  }
```

[`services/Brightness.qml:16-54`](../../config/quickshell/services/Brightness.qml#L16-L54)

The steps in between are skipped, because nobody cares about them. Note that `run()` never sets `percent`. The new value comes back through the `actual_brightness` file, the same way a brightness key's change does. One source of truth, just like the slider in chapter 6.

#### Polling

Some things can only be asked, not watched. [`components/Poller.qml`](../../config/quickshell/components/Poller.qml) runs a shell command on a timer and keeps its trimmed output in `value`:

```qml
Scope {
  id: root

  property string command: ""
  property int interval: 3000
  property string value: ""

  Process {
    id: proc
    command: ["sh", "-c", root.command]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.value = this.text.trim()
    }
  }

  Timer {
    interval: root.interval
    running: true
    repeat: true
    onTriggered: proc.running = true
  }
}
```

The media service uses it to double-check which players are really alive on D-Bus, since some players leave stale MPRIS entries behind:

```qml
  Poller {
    id: poller
    command: "busctl --user list --acquired --no-legend --no-pager | awk '{print $1}' | grep '^org\\.mpris\\.MediaPlayer2\\.'"
    interval: 2000
  }
```

[`services/Media.qml:33-37`](../../config/quickshell/services/Media.qml#L33-L37)

A poller runs all the time, so it's the last resort. There's exactly one in yurice.

#### A process as a state

Caffeine keeps the laptop awake by holding a `systemd-inhibit` lock. The lock lasts as long as the process lives, so the process's `running` is simply bound to whether caffeine is on:

```qml
  Process {
    id: inhibitor
    running: root.active && !root.releasing
    command: ["systemd-inhibit", "--what=idle:sleep:handle-lid-switch", "--mode=block", "--who=yurice", "--why=Caffeine", "sleep", "infinity"]
    ...
  }
```

[`services/Caffeine.qml:44-55`](../../config/quickshell/services/Caffeine.qml#L44-L55)

Toggle `active`, and the binding starts or kills the process. No start and stop code needed.

### 4. Streams

The last way is a long-running connection that pushes events to you, line by line. That's how yurice talks to niri, and it gets the whole next chapter.

## Where things are kept

Some services also need to remember things: your wallpaper, the current mode, your API key. [`services/Paths.qml`](../../config/quickshell/services/Paths.qml) names every place yurice keeps files:

```qml
Singleton {
  readonly property string home: Quickshell.env("HOME")
  readonly property string config: home + "/.config/yurice"
  readonly property string custom: config + "/custom"
  readonly property string state: home + "/.local/state/yurice"
  readonly property string cache: home + "/.cache/yurice"
  readonly property string shared: Quickshell.env("YURICE_STATE_ROOT") || "/var/lib/yurice"
  readonly property string scripts: Quickshell.shellDir + "/scripts"
  ...
}
```

[`services/Paths.qml:7-13`](../../config/quickshell/services/Paths.qml#L7-L13)

Each folder holds a different kind of data, and choosing the right one is part of writing a service:

| Kind     | Where                             | What                                                  | Who writes it         |
| -------- | --------------------------------- | ----------------------------------------------------- | --------------------- |
| settings | `custom/quickshell/settings.json` | your preferences: folders, idle times, clock format   | you, and the UI       |
| keys     | `~/.config/yurice/*.key`          | API credentials                                       | you, and the UI       |
| state    | `~/.local/state/yurice/*.json`    | what the shell remembers: wallpaper, mode, last query | the shell             |
| cache    | `~/.cache/yurice/`                | generated files: colors, thumbnails                   | the shell             |
| shared   | `/var/lib/yurice`                 | what the login screen needs to see                    | the shell, for greetd |

The rule of thumb: if deleting it loses something you chose, it isn't cache. Settings live under `custom/` so they sit next to your other overrides and survive a reinstall. State is safe to delete and just resets the shell's memory. Cache can always be rebuilt.

### Settings: a file you can edit by hand

[`services/Settings.qml`](../../config/quickshell/services/Settings.qml) reads `settings.json` into one `values` object and gives every key a default with `??`:

```qml
  property var values: parse(file.text())
  ...
  readonly property int idleScreenOff: values.idleScreenOff ?? 10
  readonly property int idleLock: values.idleLock ?? 30
  ...
  readonly property bool clock24h: values.clock24h ?? true
```

[`services/Settings.qml:11-23`](../../config/quickshell/services/Settings.qml#L11-L23)

The file starts out empty, and only holds what you've changed. A broken file logs a warning and falls back to `{}`, so a typo never takes the shell down. Writing goes through one function, which replaces `values` with a new object (more on why in the next chapter) and saves it:

```qml
  function set(key, value) {
    const next = Object.assign({}, values);
    next[key] = value;
    values = next;
    file.setText(JSON.stringify(next, null, 2) + "\n");
  }
```

[`services/Settings.qml:44-49`](../../config/quickshell/services/Settings.qml#L44-L49)

### State: JsonAdapter both ways

For state, yurice uses the `FileView` + `JsonAdapter` pair from chapter 3, but this time it also writes. Here's the mode service's file:

```qml
  FileView {
    id: file
    path: Paths.state + "/weeb.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loaded = true
    onLoadFailed: root.loaded = true

    JsonAdapter {
      id: state
      property string mode: "weeb"
      property string primaryName: ""
      property string secondaryName: ""
      property bool hideWallpapers: true
      ...
    }
  }
```

[`services/WeebMode.qml:89-110`](../../config/quickshell/services/WeebMode.qml#L89-L110)

The adapter's property defaults are the defaults for a fresh install. Changing state is: set the property, then save:

```qml
  function set(next) {
    if (next !== "weeb" && next !== "normie")
      return;
    state.mode = next;
    file.writeAdapter();
  }
```

`loaded` is there for services that must wait. Without it, a service could act on the defaults for a split second before the real file arrives, for example applying the wrong wallpaper at login.

### Keys: KeyFile

API keys get a tiny component of their own, [`components/KeyFile.qml`](../../config/quickshell/components/KeyFile.qml). It's a `FileView` that splits the file into trimmed `lines` and writes with a private umask:

```qml
  function write(content) {
    writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && umask 077 && printf %s "$2" > "$1"', "sh", path, content];
    writer.running = true;
  }
```

`umask 077` means the file is created readable only by you. The key is passed as an argument, never pasted into the shell string, so nothing in it can be run as a command. Danbooru keeps `lines[0]` as the username and `lines[1]` as the key. Chapter 14 shows the rest.

## Services talking to services

Services may use each other. The clock uses `Settings` for its format, `Keyboard` uses `Niri` and `Notifications`, `Caffeine` listens to `SessionLock`. Files in the same folder see each other without an import.

To react to another service's moment rather than its state, use `Connections`:

```qml
  Connections {
    target: Settings
    function onTimeFormatChanged() {
      formatSwap.restart();
    }
  }
```

[`services/Clock.qml:22-27`](../../config/quickshell/services/Clock.qml#L22-L27)

Services may also use components that hold no visuals: `Utility`, `Poller`, `KeyFile`, `SearchFeed`. They must never import `modules`. Data flows up to the UI, never back down.

One exception to "modules never touch the system": the connectivity island and the Bluetooth panel use `Quickshell.Bluetooth` directly, because the adapter and device objects are the model the panel lists. Wrapping them in a service would only copy them.

## Rules for a new service

- **One topic per service.** `Battery` knows the battery, not the power profile.
- **Expose readonly properties and functions.** Never let modules assign to a service's state directly.
- **Prefer events over polling.** Built-in service, then a watched file, then a stream, and a poller only if nothing else works.
- **Never trust the hardware to exist.** Use `?.`, `??`, `printErrors: false` and an `available` flag.
- **Let changes come back.** After writing, wait for the system to report the new value instead of setting it yourself.
- **Put data where it belongs**: settings, keys, state or cache.

One service is bigger and more central than the rest: the one that knows your windows and workspaces. That's next.
