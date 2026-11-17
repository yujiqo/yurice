# 3. The theme

Open any file in `modules/` and you won't find a single color like `"#80d5cb"`, and almost no raw sizes. Instead you'll find `Theme.primary`, `Theme.panelRadius`, `Theme.animHover`. They all come from one file: [`theme/Theme.qml`](../../config/quickshell/theme/Theme.qml).

This chapter builds that file. It's the first singleton in the book, and it's the reason a new wallpaper can recolor the whole shell without restarting anything.

## The problem

Say the volume slider is teal. You write `color: "#80d5cb"`. Then the brightness slider wants the same teal, and so does the wifi icon. A week later you change the wallpaper and want everything purple, and now you're grepping for a hex code.

There are two problems here:

1. **The same decision is written down in many places.** "Accents are teal" should exist once.
2. **The decision isn't yours to make.** The wallpaper should make it.

## Step 1: a singleton of tokens

Simplified:

```qml
pragma Singleton
import Quickshell

Singleton {
  readonly property color primary: "#80d5cb"
  readonly property int panelRadius: 22
}
```

With this saved as `theme/Theme.qml`, any file that does `import qs.theme` can say `color: Theme.primary`. Change it once and everything follows. This is what a **token** is: a named design decision.

yurice's tokens fall into groups, marked by the only comments in the codebase:

```qml
  // --- Metrics ---
  readonly property int barHeight: 30
  readonly property int barMarginTop: 10
  ...
  readonly property int panelWidth: 360
  readonly property int panelRadius: 22
  ...
  // --- Fonts ---
  readonly property string iconFont: "Material Symbols Sharp"
  readonly property int iconSize: 20
  readonly property string labelFont: "Agave Nerd Font"
  readonly property int labelSize: 18

  // --- Animation ---
  readonly property int animPress: 100
  readonly property int animHover: 120
  ...
  readonly property real animSlowdown: 1.7
  readonly property real springStiffness: 800
  readonly property real springDamping: 1.0
```

[`theme/Theme.qml:91-166`](../../config/quickshell/theme/Theme.qml#L91-L166)

The animation durations are tokens too. That's how motion stays consistent: every hover takes `animHover` milliseconds, every press takes `animPress`. Chapter 5 explains `animSlowdown` and the spring values.

## Step 2: colors come from a file

matugen writes the palette as JSON to `~/.cache/yurice/colors.json`, using the template [`config/matugen/templates/quickshell.json`](../../config/matugen/templates/quickshell.json):

```json
{
  "surface": "{{colors.surface.default.hex}}",
  "surfaceContainer": "{{colors.surface_container.default.hex}}",
  "onSurface": "{{colors.on_surface.default.hex}}",
  "primary": "{{colors.primary.default.hex}}",
  ...
}
```

quickshell can read files with `FileView`, and map JSON keys onto properties with `JsonAdapter`:

```qml
  FileView {
    id: paletteView
    path: root.paletteFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()

    JsonAdapter {
      id: palette
      property string surface
      property string surfaceContainer
      ...
      property string primary
      property string onPrimary
      ...
      property string error
    }
  }
```

[`theme/Theme.qml:62-89`](../../config/quickshell/theme/Theme.qml#L62-L89)

- **`watchChanges: true`** plus `onFileChanged: reload()` means that when matugen rewrites the file, the adapter's properties update a moment later.
- Since those are just properties, every binding that reads them runs again.

## Step 3: fallbacks

What if the file doesn't exist yet, for example on the very first start before any wallpaper is set? Every color reads its palette entry, _or_ a built-in default:

```qml
  readonly property color surface: palette.surface || "#040e0d"
  readonly property color text: palette.onSurface || "#f5e2c5"
  ...
  readonly property color primary: palette.primary || "#80d5cb"
```

[`theme/Theme.qml:33-53`](../../config/quickshell/theme/Theme.qml#L33-L53)

An empty string is false in JavaScript, so `||` falls through to the default. The shell always has _some_ theme, even with matugen missing entirely.

## Step 4: roles, not colors

Notice the names: `surface`, `surfaceContainer`, `primary`, `primaryContainer`, `outline`, `error`. These are **Material You roles**. A role describes what a color is _for_, not what it looks like:

| Role                    | Used for                                       |
| ----------------------- | ---------------------------------------------- |
| `surface`               | panel backgrounds                              |
| `surfaceContainer…`     | cards and rows sitting on a panel, in 3 levels |
| `text` (onSurface)      | normal text                                    |
| `textVariant`           | secondary text                                 |
| `primary`               | the main accent: active items, selected things |
| `textOnPrimary`         | text drawn on top of `primary`                 |
| `secondary`, `tertiary` | supporting accents                             |
| `outline`, `divider`    | borders and lines                              |
| `error`                 | warnings and failures                          |

Because matugen guarantees that `textOnPrimary` is readable on `primary` (and `text` on `surface`) for _any_ wallpaper, components that stick to matching pairs never end up with unreadable text.

## Step 5: semantic aliases

Roles are still a bit abstract when you're drawing a wifi icon. So Theme adds one more layer, colors named after the **thing**:

```qml
  // --- Accent palette ---
  readonly property color clock: tertiary
  readonly property color music: tertiary
  readonly property color wifi: primary
  ...
  readonly property color volume: secondary
  readonly property color brightness: secondary
  readonly property color good: primary
  readonly property color warn: error
```

[`theme/Theme.qml:16-30`](../../config/quickshell/theme/Theme.qml#L16-L30)

The wifi island uses `Theme.wifi`, not `Theme.primary`. If you later decide wifi should use `tertiary`, you change one line here and nowhere else.

## The whole loop

Here's what happens between picking a wallpaper and seeing new colors:

1. `Wallpapers.generatePalette(path)` starts matugen:

   ```qml
   matugen.command = ["matugen", "image", path, "-c", matugenConfig, "-m", matugen.mode, "--source-color-index", "0", "-q"];
   ```

   [`services/Wallpapers.qml:169`](../../config/quickshell/services/Wallpapers.qml#L169)
   - `-m` is `dark` or `light`, from the theme mode (chapter 17).
   - `--source-color-index 0` always picks the image's dominant color, so you're never asked to choose.

2. matugen reads [`config/matugen/config.toml`](../../config/matugen/config.toml) and fills every template. One of them is `colors.json`.
3. `Theme`'s `FileView` sees the file change and reloads.
4. Every `palette.*` property changes. Every token built on them changes. Every binding anywhere that reads a token updates.

No component ever asked to be recolored. They just _are_ `Theme.surface`, and `Theme.surface` changed.

## Theming the rest of the desktop

The other templates in [`config/matugen/config.toml`](../../config/matugen/config.toml) follow the same pattern, plus a `post_hook` that tells the program to reload:

```toml
[templates.kitty]
input_path = "templates/kitty.conf"
output_path = "~/.cache/yurice/kitty-colors.conf"
post_hook = "pkill -USR1 kitty || true"

[templates.niri]
input_path = "templates/niri.kdl"
output_path = "~/.cache/yurice/niri-colors.kdl"
post_hook = "niri msg action load-config-file || true"
```

kitty, niri, neovim and tmux each `include` the generated file from their main config. Chapter 22 shows where.

The `[config.custom_colors]` table at the top of that file defines extra named colors (clock gold, music pink, wifi blue…) that matugen **blends** toward the wallpaper's palette, so they shift to fit each wallpaper. They exist for terminals and editors, which need a recognizable red, green, yellow and blue no matter what the wallpaper looks like. kitty's 16 ANSI colors and neovim's base16 palette are built from them. The shell itself sticks to the Material roles from step 5.

## Rules to follow

- **Never write a color literal in a component or module.** Add a token, or use a role.
- **Use the matching "on" color** for anything drawn on top of an accent.
- **A new size used in more than one place becomes a token.** A one-off number inside a single component is fine. That's why some layout numbers still live in `PanelHeader.qml` and friends.

## Recap

- `Theme.qml` is a singleton of tokens: colors, sizes, fonts and durations.
- Colors come from `~/.cache/yurice/colors.json`, written by matugen, watched live, with built-in fallbacks.
- Components use _roles_ and _semantic aliases_, never hex codes. That's why one wallpaper change recolors everything.

With a theme in hand, we can build the first real pieces.
