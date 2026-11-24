# 15. The user island

The leftmost island is your avatar, with your name on hover. Its panel is where yurice keeps everything about you and your machine: a little system info, and a settings page that writes `settings.json` for you. It also holds two editors big enough that the panel widens for them, one for your avatar and one for your monitors.

## The panel

[`modules/bar/UserPanel.qml`](../../config/quickshell/modules/bar/UserPanel.qml) shows your name and `user@hostname`, then a card of facts: uptime, hostname, kernel, OS version, and on NixOS the current system generation and its date. [`services/SystemInfo.qml`](../../config/quickshell/services/SystemInfo.qml) collects them with one run of [`scripts/system-info.sh`](../../config/quickshell/scripts/system-info.sh), and the panel asks for a refresh each time it opens, so the generation is current right after a rebuild. Uptime is computed from the boot time and `Clock.date`, so it ticks without running anything.

Below that, a "Settings" row expands into [`UserSettings.qml`](../../config/quickshell/modules/bar/UserSettings.qml).

## The settings page

The settings page is long but repetitive, so it introduces one more QML feature: inline components. A `component Name: Type { … }` declaration inside a file defines a small type that only that file can use. The page defines four of them and then mostly just lists rows.

A `Group` is a section title over a card:

```qml
  component Group: Column {
    id: group

    property string title: ""
    default property alias rows: card.content

    width: parent.width
    spacing: 2

    SectionTitle {
      title: group.title
    }

    Card {
      id: card
    }
  }
```

[`modules/bar/UserSettings.qml:34-50`](../../config/quickshell/modules/bar/UserSettings.qml#L34-L50)

A `DurationRow` is a [`StepperRow`](../../config/quickshell/components/StepperRow.qml) (an `InfoRow` with − and + buttons) bound to one setting:

```qml
  component DurationRow: StepperRow {
    property string key: ""
    readonly property int minutes: Settings[key]

    valueText: minutes > 0 ? Utility.formatDuration(minutes * 60) : "Never"
    canDecrease: minutes > 0
    canIncrease: minutes < root.minuteSteps[root.minuteSteps.length - 1]
    onDecreased: Settings.set(key, root.stepMinutes(minutes, -1))
    onIncreased: Settings.set(key, root.stepMinutes(minutes, 1))
  }
```

[`modules/bar/UserSettings.qml:52-61`](../../config/quickshell/modules/bar/UserSettings.qml#L52-L61)

`Settings[key]` reads a property by name, so one row type serves every duration. The buttons step through a fixed list (0, 1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90 and 120 minutes) instead of adding one minute at a time, since nobody wants to click 29 times to get from 1 minute to 30. Zero shows as "Never".

With those, the idle section is four lines per setting:

```qml
  Group {
    title: "Idle"

    DurationRow {
      icon: "monitor"
      label: "Screens off"
      key: "idleScreenOff"
    }
    ...
  }
```

The page has sections for the profile picture, displays, which islands are on the bar, idle times, the clock, the weather (units and location) and folders. Every row writes through `Settings.set`, and nothing else. Since `Settings` watches its file, editing `settings.json` by hand updates the page live too.

### Folders

`PathRow` is the one row that checks your input before saving. When you enter a folder for wallpapers, danbooru downloads or screenshots, it runs a tiny shell test first:

```qml
    Process {
      id: check
      command: ["sh", "-c", 'mkdir -p "$1" && test -d "$1" && test -w "$1"', "sh", Paths.expand(row.pending)]
      onExited: code => {
        if (code !== 0) {
          row.error = "Can't create or write to this folder";
          return;
        }
        ...
        Settings.set(row.key, display);
        row.confirm();
      }
    }
```

[`modules/bar/UserSettings.qml:124-136`](../../config/quickshell/modules/bar/UserSettings.qml#L124-L136)

The folder is created if needed, and the setting is only saved if it exists and is writable afterwards. The path is stored with `~` (from `Paths.display`), so `settings.json` stays portable between machines with different usernames. Clearing the field removes the key, which brings back the default.

### Weather location

The location row is a search box. Typing calls `Weather.search`, which asks open-meteo's geocoding API for up to six places, and picking one stores `{ name, latitude, longitude }` as `weatherLocation`. "Use automatic location" removes it again, and the weather service goes back to ipinfo (chapter 14).

## Idle

The idle durations aren't used by the user island at all. They're read by four `IdleMonitor`s in [`services/SessionLock.qml`](../../config/quickshell/services/SessionLock.qml):

```qml
  IdleMonitor {
    enabled: root.phase === "idle" && Settings.idleScreenOff > 0 && !Caffeine.active
    timeout: Math.max(1, Settings.idleScreenOff) * 60
    onIsIdleChanged: {
      if (isIdle)
        Qt.callLater(root.powerOffMonitors);
    }
  }
```

[`services/SessionLock.qml:302-309`](../../config/quickshell/services/SessionLock.qml#L302-L309)

`IdleMonitor` is quickshell's wrapper around Wayland's idle notification protocol: the compositor tells it when you've been inactive for `timeout` seconds. There's one monitor per setting. While unlocked, one turns the screens off and one locks. While locked, one turns the screens off again and one suspends. Each is disabled when its setting is 0 or caffeine is on, which is all caffeine really is on the shell side. The monitors only depend on settings, so changing a duration takes effect immediately with no restart. Chapter 20 covers the lock itself.

## The avatar editor

Each mode has its own profile picture (chapter 16), stored as `custom/avatars/weeb.jpg` and `normie.jpg`. The "Profile picture" section opens an editor for either one, and the panel widens from 380 to 560 pixels while it's open:

```qml
  panelWidth: AvatarEditor.active || Displays.editing ? 560 : 380
```

[`modules/bar/UserIsland.qml:15`](../../config/quickshell/modules/bar/UserIsland.qml#L15)

The editor's state lives in [`services/AvatarEditor.qml`](../../config/quickshell/services/AvatarEditor.qml): which avatar you're changing, which folder you're browsing, and which file you picked. Keeping it in a service rather than the panel means the panel can cross-fade between its three views (main, avatar, displays) without any of them owning the state.

The editor has two steps. [`AvatarBrowser.qml`](../../config/quickshell/modules/bar/AvatarBrowser.qml) is a small file browser that starts in `~/Pictures` and shows image thumbnails. [`AvatarCropper.qml`](../../config/quickshell/modules/bar/AvatarCropper.qml) shows the picked image with a circle over it. You drag the circle to move it, and scroll or drag its handle to resize it. The circle is stored as a center and radius in fractions of the image (0 to 1), not pixels, so it doesn't matter how big the preview is.

Saving hands those fractions to [`scripts/crop-avatar.sh`](../../config/quickshell/scripts/crop-avatar.sh), which uses ImageMagick to crop, resize to 512×512, strip metadata, and replace the old avatar through a temporary file. Then the service does two things:

```qml
      Settings.set("avatarRevision", Date.now());
      WallpaperPublish.schedule();
```

[`services/AvatarEditor.qml:71-72`](../../config/quickshell/services/AvatarEditor.qml#L71-L72)

The avatar file keeps the same path, and QML caches images by URL, so without help every `Avatar` on screen would keep showing the old picture. [`Avatar.qml`](../../config/quickshell/components/Avatar.qml) adds the revision to the URL (`weeb.jpg?v=1732…`), and a new revision makes it a new URL. Storing the revision in settings means it also survives a restart. `WallpaperPublish.schedule()` copies the new avatar to where the login screen can read it (chapter 20).

## The display editor

The "Displays" row opens an editor for your monitors: resolution, refresh rate, scale, rotation, and their arrangement, which you set by dragging monitors around a small canvas. [`services/Displays.qml`](../../config/quickshell/services/Displays.qml) holds the logic. It's the most careful code in the shell, because a wrong display setting can leave you with no usable screen.

### Draft and outputs

The service keeps two copies. `outputs` is what niri reports right now, read with `niri msg -j outputs`. `draft` is what you're editing. Every change in the editor goes into `draft`, and `dirty` is true while the two differ. Nothing touches the real monitors until you press apply.

Dragging a monitor goes through `snapIn`, which places it against an edge of another monitor, lined up with that monitor's top, bottom or center when it's close, and never overlapping. You can't create a layout with gaps or overlaps by dragging.

### Apply, then confirm

Applying turns the draft into `niri msg output` commands, one line per setting per monitor:

```qml
  function commandsFor(states) {
    const lines = [];
    const names = Object.keys(states);
    names.filter(n => states[n].enabled).forEach(n => {
      const s = states[n];
      const q = `'${n}'`;
      lines.push(`niri msg output ${q} on`);
      lines.push(`niri msg output ${q} mode ${modeText(s)}`);
      lines.push(`niri msg output ${q} scale ${s.scale}`);
      lines.push(`niri msg output ${q} transform ${s.transform}`);
      lines.push(`niri msg output ${q} position set -- ${Math.round(s.x)} ${Math.round(s.y)}`);
    });
    names.filter(n => !states[n].enabled).forEach(n => lines.push(`niri msg output '${n}' off`));
    return lines.join("\n");
  }
```

[`services/Displays.qml:298-312`](../../config/quickshell/services/Displays.qml#L298-L312)

Monitors are turned on before others are turned off, so there's always at least one screen lit, and `apply` refuses a draft with no enabled monitors at all.

These commands change niri's live state only, not its config. Before running them, `apply` saves the current state as `snapshot`, closes the panel, and starts a 10 second countdown. [`DisplayConfirm.qml`](../../config/quickshell/modules/bar/DisplayConfirm.qml) shows a dialog on every monitor that changed, asking whether to keep the new settings. If you pick "Revert", or don't answer before the countdown ends, the snapshot is applied again. That's what makes a broken mode safe: if the screen goes black, you wait ten seconds.

### Keeping it

Only "Keep" makes the change permanent, in two places:

```qml
    Settings.set("outputs", stored);
    writeKdl(stored);
```

[`services/Displays.qml:372-373`](../../config/quickshell/services/Displays.qml#L372-L373)

`writeKdl` writes an `output` block per monitor to `~/.config/yurice/custom/niri/outputs.kdl`, which niri's config includes (chapter 21). That's what applies your layout on the next login, and since it's a plain KDL file in `custom/`, you can also edit it by hand.

The copy in `settings.json` is for the editor. niri reports nothing useful for a monitor that's turned off: no mode, no position. Without a saved copy, turning a monitor off and back on would lose its resolution and place. `parse` falls back to the stored values for exactly that case.

After keeping or reverting, the user panel reopens on the display editor, so you can carry on where you were.

The user island is personal in another way too: what it shows depends on which mode you're in.
