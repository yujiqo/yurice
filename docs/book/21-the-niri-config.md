# 21. The niri config

Part V covers the parts of yurice that aren't QML. This chapter is niri's config. You've seen pieces of it already: the keybinds in chapter 9, the animation slowdown in chapter 5, the generated colors in chapter 3. Here's the whole thing and how it fits together.

## One file of includes

[`config/niri/config.kdl`](../../config/niri/config.kdl) is nothing but includes:

```kdl
include "modules/input.kdl"
include "modules/layout.kdl"
include optional=true "~/.cache/yurice/niri-colors.kdl"
include "modules/rules.kdl"
include "modules/startup.kdl"
include "modules/misc.kdl"
include "modules/binds.kdl"
include optional=true "~/.config/yurice/custom/niri/outputs.kdl"
include optional=true "~/.config/yurice/custom/niri/config.kdl"
```

[`config/niri/config.kdl`](../../config/niri/config.kdl)

Each module is one topic, which keeps the files short and lets the cheatsheet parser read `binds.kdl` alone (chapter 9). niri merges included files in order, and when two files set the same thing, the later one wins. The order is chosen with that in mind:

- `niri-colors.kdl` comes right after `layout.kdl`, so the wallpaper's colors replace the placeholder colors there.
- `optional=true` means a missing file isn't an error. The colors don't exist until matugen first runs, and the two custom files only exist if you or the display editor made them.
- The custom files come last, so anything in them overrides anything yurice sets.

niri watches its config and all included files, and reloads on any change. That's why saving `binds.kdl` updates both niri and the cheatsheet at once, and why matugen's post hook can just run `niri msg action load-config-file`.

## Input

[`modules/input.kdl`](../../config/niri/modules/input.kdl) sets a fast key repeat (300 ms delay, 30 per second), tap to click, natural scrolling and disable-while-typing on touchpads, and a slower trackpoint. Two lines are worth explaining:

```kdl
  focus-follows-mouse max-scroll-amount="0%"

  mod-key "Super"
```

[`config/niri/modules/input.kdl:30-32`](../../config/niri/modules/input.kdl#L30-L32)

Focus follows the mouse, but never scrolls the view to do it. In a scrolling layout, plain focus-follows-mouse would slide columns around every time the cursor crossed a half-visible window. With `0%`, moving the mouse only focuses windows that are already fully on screen.

`mod-key` is what `Mod` means in every bind. It's set explicitly because niri uses `Alt` as `Mod` when it runs nested inside another compositor, and yurice's binds are written for `Super`.

Hot corners are off. The overview is on `Mod+O` instead.

## Layout

[`modules/layout.kdl`](../../config/niri/modules/layout.kdl) decides how windows are arranged:

```kdl
layout {
  gaps 10
  background-color "transparent"

  center-focused-column "never"
  always-center-single-column
  empty-workspace-above-first

  preset-column-widths {
    proportion 0.33333
    proportion 0.5
    proportion 0.66667
  }

  default-column-width { proportion 0.5; }
  ...
```

[`config/niri/modules/layout.kdl:9-23`](../../config/niri/modules/layout.kdl#L9-L23)

New windows open at half the screen width, and `Mod+R` cycles through a third, a half and two thirds. A lone window is centered instead of hugging the left edge. `empty-workspace-above-first` keeps an empty workspace at the top as well as the bottom, so you can start a new workspace in either direction.

`background-color "transparent"` lets the wallpaper show through between windows. The wallpaper isn't drawn by niri at all, it's the quickshell window on the background layer from chapter 17.

The focus ring and border are both off. The border's colors are still defined, though, and matugen's `niri-colors.kdl` fills them from the wallpaper:

```kdl
layout {
  border {
    active-gradient from="{{colors.primary.default.hex}}" to="{{colors.tertiary.default.hex}}" angle=45
    inactive-color "{{colors.outline_variant.default.hex}}"
    urgent-color "{{colors.error.default.hex}}"
  }
}
```

[`config/matugen/templates/niri.kdl`](../../config/matugen/templates/niri.kdl)

So if you turn borders on in your custom config, they're already in your wallpaper's colors.

The overview's backdrop is black and workspace shadows are off.

## Rules

[`modules/rules.kdl`](../../config/niri/modules/rules.kdl) has one layer rule and a few window rules:

```kdl
layer-rule {
  match namespace="^yurice-wallpaper$"
  place-within-backdrop true
}

window-rule {
  geometry-corner-radius 10
  draw-border-with-background false
  clip-to-geometry true
}
```

[`config/niri/modules/rules.kdl:1-10`](../../config/niri/modules/rules.kdl#L1-L10)

The layer rule matches the wallpaper window by the namespace chapter 17 gave it, `yurice-wallpaper`, and puts it in niri's backdrop. The backdrop is what niri shows behind the workspaces in the overview, so the wallpaper stays visible there instead of a plain color. This is why every quickshell window in yurice sets a `WlrLayershell.namespace`: it's how niri rules can tell them apart.

The window rule rounds every window's corners to 10 pixels and clips the content to that shape, so windows match the shell's rounded islands.

The rest are app fixes: OBS opens maximized, and Steam's main window doesn't open fullscreen, while its news and notification popups float, with toasts in the bottom right corner and without stealing focus.

## Startup and misc

```kdl
spawn-at-startup "xwayland-satellite"
spawn-at-startup "qs"
```

[`config/niri/modules/startup.kdl`](../../config/niri/modules/startup.kdl)

X11 apps run through [xwayland-satellite](https://github.com/Supreeeme/xwayland-satellite). `qs` starts the shell with `shell.qml` from `~/.config/quickshell`. Everything else the desktop needs (the cliphist watchers, the polkit agent) runs as systemd user services set up by the installer.

[`modules/misc.kdl`](../../config/niri/modules/misc.kdl) skips niri's own hotkey overlay at startup (yurice has the cheatsheet), asks apps to drop their client-side title bars with `prefer-no-csd`, sets niri's built-in screenshot path to the same folder and name format as yurice's screenshots, and sets `animations { slowdown 1.7 }`, which must match `Theme.animSlowdown` (chapter 5).

## Your additions

The two custom includes are where your machine-specific config goes:

- `~/.config/yurice/custom/niri/outputs.kdl` holds `output` blocks. The display editor writes it when you keep a new layout (chapter 15). You can edit it by hand too, but the editor rewrites the whole file the next time you keep a change there.
- `~/.config/yurice/custom/niri/config.kdl` is for anything else: extra binds, window rules for your apps, different gaps, your keyboard layouts.

For example, adding a second keyboard layout:

```kdl
input {
  keyboard {
    xkb {
      layout "us,ru"
      options "grp:win_space_toggle"
    }
  }
}
```

Because the file is included last, this merges into yurice's `input` block. Key repeat and the rest stay as they are, and switching layouts shows the toast from chapter 8. [CUSTOMIZING](../CUSTOMIZING.md) lists every custom file.

Binds added here work, but they don't show up in the cheatsheet, which only reads `binds.kdl` (chapter 9).

The other half of Part V is the terminal.
