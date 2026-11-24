# 9. IPC and keybinds

On Wayland, programs can't listen to the keyboard globally. Only the compositor sees every key press, and it sends each one to the focused window. That's good for security, since no app can quietly log your typing. But it means the shell can't just listen for `Mod+A` and open the volume panel.

The solution has two halves. niri owns the shortcuts and runs a command when one is pressed. The shell exposes commands that can be called from outside. This chapter connects them, and then turns the same keybind file into the cheatsheet you get with `Mod+Shift+/`.

## IpcHandler: functions you can call from a terminal

quickshell has a built-in IPC (Inter-Process Communication) system. Put an `IpcHandler` in any object, give it a `target` name, and its functions become callable with `qs ipc call`:

```qml
  IpcHandler {
    target: "panel"

    function toggle(name: string): void {
      root.toggle(name);
    }
    function open(name: string): void {
      root.open(name);
    }
    function close(): void {
      root.close();
    }
  }
```

[`services/Panels.qml:34-46`](../../config/quickshell/services/Panels.qml#L34-L46)

With the shell running, try:

```sh
qs ipc show                         # list every target and its functions
qs ipc call panel toggle weather    # open the weather panel
qs ipc call weeb get                # print the current mode
```

The type annotations (`name: string`, `: void`) aren't optional here, as they are in the rest of QML. quickshell uses them to turn command-line words into the right types and to print return values. Arguments can be `string`, `int`, `real`, `bool` or `color`.

Keep the handler thin. Each function just calls the service's own function, so the keyboard path and the mouse path run the exact same code.

## Every target in yurice

| Target       | Functions                                                                       | Lives in                                                              |
| ------------ | ------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `panel`      | `toggle(name)`, `open(name)`, `close()`                                         | [`Panels.qml`](../../config/quickshell/services/Panels.qml)           |
| `launcher`   | `toggle()`, `toggleClipboard()`, `close()`                                      | [`Launcher.qml`](../../config/quickshell/services/Launcher.qml)       |
| `power`      | `toggle()`, `open()`, `close()`                                                 | [`Session.qml`](../../config/quickshell/services/Session.qml)         |
| `wallpaper`  | `toggle()`, `open()`, `close()`, `set(path)`, `regenerate()`, `get()`, `list()` | [`Wallpapers.qml`](../../config/quickshell/services/Wallpapers.qml)   |
| `theme`      | `toggle()`, `set(mode)`, `get()`, `setAuto(on)`                                 | [`ThemeMode.qml`](../../config/quickshell/services/ThemeMode.qml)     |
| `weeb`       | `toggle()`, `set(mode)`, `get()`                                                | [`WeebMode.qml`](../../config/quickshell/services/WeebMode.qml)       |
| `caffeine`   | `toggle()`, `set(on)`, `get()`                                                  | [`Caffeine.qml`](../../config/quickshell/services/Caffeine.qml)       |
| `lock`       | `lock()`, `isLocked()`                                                          | [`SessionLock.qml`](../../config/quickshell/services/SessionLock.qml) |
| `screenshot` | `start()`, `cancel()`                                                           | [`Screenshot.qml`](../../config/quickshell/services/Screenshot.qml)   |

The panel names for `panel` are listed in `Panels.names`: `user`, `media`, `wallpapers`, `danbooru`, `theme`, `weeb`, `weather`, `wifi`, `bluetooth`, `volume`, `brightness`, `battery`, `calendar` and `hotkeys`.

IPC is also handy for your own scripts. `qs ipc call wallpaper set ~/Pictures/x.jpg` from a cron job, `qs ipc call theme set light` from a script, or `qs ipc call caffeine set true` before a long download.

## The niri side

niri's keybinds live in [`config/niri/modules/binds.kdl`](../../config/niri/modules/binds.kdl). A bind that talks to the shell just spawns `qs`:

```kdl
binds {
  // section: Shell
  Mod+Shift+Slash repeat=false hotkey-overlay-title="Keyboard shortcuts" { spawn "qs" "ipc" "call" "panel" "toggle" "hotkeys"; }
  ...
  // section: Panels
  Mod+P repeat=false hotkey-overlay-title="Media" { spawn "qs" "ipc" "call" "panel" "toggle" "media"; }
```

[`config/niri/modules/binds.kdl:1-12`](../../config/niri/modules/binds.kdl#L1-L12)

`spawn` takes the command as separate words, with no shell in between. `repeat=false` stops a held key from toggling the panel open and shut many times a second. `hotkey-overlay-title` is the human name for the bind; niri uses it in its own overlay, and so does yurice's cheatsheet. The `// section:` comments mean nothing to niri. They're for the cheatsheet too, as you'll see below.

### Not every key goes through the shell

Look at the media keys:

```kdl
  XF86AudioRaiseVolume allow-when-locked=true hotkey-overlay-title="Volume up" { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
```

[`config/niri/modules/binds.kdl:31`](../../config/niri/modules/binds.kdl#L31)

The volume key calls PipeWire's `wpctl` directly, not the shell. That's deliberate. It works even if the shell has crashed or is restarting, and `allow-when-locked=true` lets it work on the lock screen. The shell still finds out. PipeWire tells the `Audio` service, and the volume island updates like it would after any other change. One source of truth again: nobody tells the shell "volume went up", it just sees it.

The rule: if a key changes the system, let it talk to the system. If it changes the shell (opens a panel, starts a screenshot), go through IPC.

## From key press to open panel

Follow `Mod+A` all the way:

1. niri sees `Mod+A` and runs `qs ipc call panel toggle volume`.
2. That command finds the running shell and calls `Panels.toggle("volume")`.
3. `Panels.open` checks the name and remembers which monitor you're on:

   ```qml
     function open(next) {
       if (!names.includes(next) || !Islands.panelShown(next))
         return;
       output = Niri.activeOutput;
       name = next;
     }
   ```

   [`services/Panels.qml:16-21`](../../config/quickshell/services/Panels.qml#L16-L21)

   `Islands.panelShown` stops it from opening a panel whose island you've hidden (chapter 16). `Niri.activeOutput` is from the last chapter.

4. Every bar has a binding that only matches on its own monitor:

   ```qml
     readonly property string keyboardPanel: Panels.output === modelData.name ? Panels.name : ""
   ```

   [`modules/bar/Bar.qml:17`](../../config/quickshell/modules/bar/Bar.qml#L17)

5. When it changes, that bar opens the matching dropdown:

   ```qml
     onKeyboardPanelChanged: {
       if (keyboardPanel !== "")
         dropdown = keyboardPanel;
       else if (Panels.names.includes(dropdown))
         dropdown = "";
     }
   ```

   [`modules/bar/Bar.qml:31-36`](../../config/quickshell/modules/bar/Bar.qml#L31-L36)

6. The volume island sees `dropdown === "volume"` and grows into its panel (chapter 11).

It also works the other way. If you close the panel with `Esc` or a click, the bar's `dropdown` changes first, and the bar tells `Panels` so the two never disagree:

```qml
    if (keyboardPanel !== "" && dropdown !== keyboardPanel)
      Panels.close();
```

[`modules/bar/Bar.qml:67-68`](../../config/quickshell/modules/bar/Bar.qml#L67-L68)

There are two pieces of state here, the global `Panels.name` and each bar's own `dropdown`. They're needed because a click on an island is local to one bar, while a keybind is global. The two `on…Changed` handlers keep them in step. The launcher and power menu use the same pattern with `Launcher.output` and `Session.output`.

## The cheatsheet

`Mod+Shift+/` opens a panel listing every shortcut. Nobody maintains that list by hand. [`services/Hotkeys.qml`](../../config/quickshell/services/Hotkeys.qml) reads `binds.kdl` and builds it:

```qml
  FileView {
    path: Paths.home + "/.config/niri/modules/binds.kdl"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parse(text())
  }
```

[`services/Hotkeys.qml:99-105`](../../config/quickshell/services/Hotkeys.qml#L99-L105)

Because it's watched, adding a bind and saving the file updates the cheatsheet immediately. niri reloads its own config on save too, so the new key works at the same moment it appears in the list.

### Parsing, one line at a time

KDL is a full language, but a bind line has a very regular shape: keys, some `name=value` attributes, then `{ action; }`. So instead of a real KDL parser, `parse` reads the file line by line with three regular expressions:

```qml
    const section = /^\s*\/\/\s*section:\s*(.+?)\s*$/;
    const bind = /^\s*([A-Za-z0-9_+]+)((?:\s+[a-z-]+=(?:"(?:[^"\\]|\\.)*"|\S+))*)\s*\{\s*(.*?)\s*\}\s*$/;
    const titleAttr = /hotkey-overlay-title=(null|"((?:[^"\\]|\\.)*)")/;
```

[`services/Hotkeys.qml:60-62`](../../config/quickshell/services/Hotkeys.qml#L60-L62)

A `// section: Name` comment starts a new group. Any other comment is skipped, which is how the commented-out alternatives in `binds.kdl` stay out of the list. A bind line is split into keys (`Mod+Shift+Slash`), attributes, and the action. Binds with `hotkey-overlay-title=null` are skipped, and so are binds for niri's own `show-hotkey-overlay`. That's how you hide a bind from the cheatsheet.

Then each bind gets a title. If it has a `hotkey-overlay-title`, that's used. Otherwise `humanize` makes one from the action: `close-window` becomes "Close window", and `set-column-width "-10%"` becomes "Set column width -10%". You only write a title when the action's name isn't clear enough on its own.

Key names get the same treatment. `keysOf` splits `Mod+Shift+Slash` on `+` and maps each part through `keyNames`: `Mod` becomes "Super", `Slash` becomes "/", `XF86AudioRaiseVolume` becomes "Vol +". The panel then draws each key as a keycap.

The result is a plain array of sections, each with a title and a list of binds:

```js
[{ title: "Shell", binds: [{ keys: ["Super", "Shift", "/"], title: "Keyboard shortcuts" }, ...] }, ...]
```

### Showing it

[`modules/bar/HotkeysPanel.qml`](../../config/quickshell/modules/bar/HotkeysPanel.qml) is two nested `Repeater`s, one for sections (each with a `SectionTitle`) and one for binds (each a `KeyRow`). It also handles its own keys, since a long read-only list needs scrolling, not focus moving: `j`/`k` scroll a step, `Ctrl+D`/`Ctrl+U` half a page, `g`/`G` jump to the top and bottom.

### What it doesn't see

Only `binds.kdl` is read. Binds you add in `~/.config/yurice/custom/niri/config.kdl` work, but don't show up in the cheatsheet. For now, that's the price of keeping the parser tiny: reading every included file, and working out which bind wins when two files define the same key, would make it a real KDL implementation. [KEYBINDS](../KEYBINDS.md) mentions this.

## Adding a keybind

Putting it all together, a new shell shortcut takes two steps:

1. Give the service an IPC function, if it doesn't have one:

   ```qml
   IpcHandler {
     target: "caffeine"
     function toggle(): void {
       root.toggle();
     }
   }
   ```

2. Add a line to `binds.kdl` under the right `// section:`, with a title:

   ```kdl
   Mod+Shift+B repeat=false hotkey-overlay-title="Toggle caffeine" { spawn "qs" "ipc" "call" "caffeine" "toggle"; }
   ```

Save, and it works and shows up in the cheatsheet. Remember to add it to [KEYBINDS](../KEYBINDS.md) too.

That's the end of Part II. The shell can draw, and now it knows what the system is doing and listens to your keys. Part III puts it all together into the bar.
