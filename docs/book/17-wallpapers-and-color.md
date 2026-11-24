# 17. Wallpapers and color

Part IV leaves the bar. This chapter follows the wallpaper: where the list comes from, how it's drawn, how you pick a new one, how it becomes the color scheme, and how it reaches the login screen. Chapter 3 covered the color loop from the theme's side. This is the same loop from the wallpaper's side.

## The list

[`services/Wallpapers.qml`](../../config/quickshell/services/Wallpapers.qml) finds wallpapers with a `FolderListModel`, Qt's model of a directory's contents:

```qml
  FolderListModel {
    id: folder
    folder: Paths.fileUrl(root.directory)
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
    caseSensitive: false
    showDirs: false
    sortField: FolderListModel.Name
    onCountChanged: root.rebuild()
    onStatusChanged: if (status === FolderListModel.Ready)
      root.rebuild()
  }
```

[`services/Wallpapers.qml:252-262`](../../config/quickshell/services/Wallpapers.qml#L252-L262)

The folder is `~/Pictures/Wallpapers` unless you change it in settings. The model watches it, so copying a file in from a file manager or a terminal adds it to the picker straight away. `rebuild()` copies the paths and modification times into plain properties, since everything else in the shell wants arrays, not a model.

Two background jobs run whenever the list changes. One measures every image's resolution with a single `magick identify -ping` run (`-ping` reads only the header, not the pixels), which the library uses to show sizes and offer upscaling. The other makes thumbnails with [`scripts/wallpaper-thumbs.sh`](../../config/quickshell/scripts/wallpaper-thumbs.sh) into `~/.cache/yurice/wallpaper-thumbs`. A thumbnail's file name is an MD5 of the path, the modification time and the thumbnail size, so editing a wallpaper or changing monitors makes a new thumbnail without any explicit cache invalidation.

## What "current" means

The current wallpaper isn't stored as one value. It's a binding:

```qml
  readonly property string current: {
    if (!ready)
      return "";
    if (!hideUnsafe)
      return state.path || (allWallpapers.length > 0 ? allWallpapers[0] : "");
    if (state.normiePath !== "" && isSafe(state.normiePath))
      return state.normiePath;
    return wallpapers.length > 0 ? wallpapers[0] : "";
  }
```

[`services/Wallpapers.qml:24-32`](../../config/quickshell/services/Wallpapers.qml#L24-L32)

It's empty until the state files are loaded, then it's the remembered wallpaper for the current mode (chapter 16), falling back to the first one in the folder. `set(path)` only writes `state.path` or `state.normiePath`, and `current` follows. Everything that reacts to a wallpaper change, the drawing, matugen, the greeter copy, watches `current`.

## Drawing it

[`modules/wallpaper/Wallpaper.qml`](../../config/quickshell/modules/wallpaper/Wallpaper.qml) is one full-screen `PanelWindow` per monitor on the `Background` layer, under every window:

```qml
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Background
  WlrLayershell.namespace: "yurice-wallpaper"
```

[`modules/wallpaper/Wallpaper.qml:21-23`](../../config/quickshell/modules/wallpaper/Wallpaper.qml#L21-L23)

`ExclusionMode.Ignore` lets it cover the whole screen, including the area the bar reserves.

It holds two images, `a` and `b`, and cross-fades between them the same way `Disc` swaps covers in chapter 4. The new wallpaper loads into the back image, and only when its status is `Ready` does it fade in over the front one. Then the two trade roles:

```qml
  function swap() {
    const old = front;
    front = back;
    front.opacity = 1;
    old.opacity = 0;
    old.path = "";
  }
```

[`modules/wallpaper/Wallpaper.qml:60-66`](../../config/quickshell/modules/wallpaper/Wallpaper.qml#L60-L66)

Clearing `old.path` unloads the old image, so only one full-resolution wallpaper sits in memory per screen once the fade is done.

Each image sets `sourceSize` to the screen's size in physical pixels. A 6000 pixel wide photo is decoded straight to screen size instead of at full size and then scaled down, which saves a lot of memory and time on a big image. If a pre-resized copy of the current wallpaper exists (see "The greeter copy" below), that's loaded instead of the original, which is faster still.

## The picker

`Mod+W` opens [`modules/wallpaper/WallpaperPicker.qml`](../../config/quickshell/modules/wallpaper/WallpaperPicker.qml), a full-screen overlay on the screen you're using. It's the most animated thing in yurice, and it's built on a single idea: the picker is a grid of screen-sized tiles, viewed from far away.

Every tile is exactly the size of the screen. The grid is as square as possible, `ceil(sqrt(n))` columns. A camera, made of two springs for the focus point and one for the zoom, looks at the grid:

```qml
  readonly property real progress: progressSpring.value
  readonly property real zoom: 1 + (Theme.pickerScale - 1) * progress
```

[`modules/wallpaper/WallpaperPicker.qml:20-21`](../../config/quickshell/modules/wallpaper/WallpaperPicker.qml#L20-L21)

At `progress` 0 the zoom is 1, and the current wallpaper's tile fills the screen exactly, so it looks like your desktop. At 1 the zoom is `pickerScale`, 0.3, and you see the tiles around it. Opening the picker is just springing `progress` from 0 to 1: your wallpaper shrinks into its place in the grid and its neighbours come into view. The tiles' corner radius is scaled with the zoom so they look rounded at the far end and square when full screen.

Moving with the arrows or `hjkl` moves the focus springs to another tile. `Enter` sets the new wallpaper and springs `progress` back to 0, so the picked tile grows until it fills the screen. `Esc` does the same toward the original tile. Since the picker's last frame is pixel for pixel the new wallpaper, closing it shows no seam.

The picker waits for its thumbnails before it opens, with a short timeout as a safety net. Animating a zoom over tiles that are still blank would look broken. While it covers a screen, it sets `Wallpapers.coveredOutput`, and the real wallpaper under it swaps instantly instead of cross-fading, since nobody can see it.

## From wallpaper to colors

When `current` changes, `Wallpapers` runs matugen:

```qml
  function generatePalette(path) {
    if (path === "")
      return;
    if (matugen.running) {
      pendingPalette = path;
      return;
    }
    matugen.path = path;
    matugen.mode = ThemeMode.mode;
    matugen.command = ["matugen", "image", path, "-c", matugenConfig, "-m", matugen.mode, "--source-color-index", "0", "-q"];
    matugen.running = true;
  }
```

[`services/Wallpapers.qml:226-237`](../../config/quickshell/services/Wallpapers.qml#L226-L237)

This is the brightness queue from chapter 7 again. Flicking through wallpapers quickly can't start ten matugen runs at once: one runs, the latest request waits, and the ones in between are dropped.

When matugen finishes, the service records which wallpaper the palette was made from, tells `ThemeMode` which mode it was made for, and asks `Theme` to reload. matugen's post hooks have already told kitty, niri and the rest to reload their own files (chapter 3).

On startup, `checkPalette()` runs `test -f` on `colors.json` and generates it if it's missing, so a fresh install gets colors on its first run. `syncPalette()` regenerates when the remembered palette doesn't match the current wallpaper, which covers changing the wallpaper by editing `wallpaper.json` by hand, or the shell being killed mid-run.

## Light and dark

[`services/ThemeMode.qml`](../../config/quickshell/services/ThemeMode.qml) decides between light and dark. Manually, `Mod+Shift+Z` or a right click on the theme island flips it. Automatically, it follows a daily schedule, light from 08:00 to 16:00 by default, and the theme panel lets you move both ends:

```qml
  readonly property string scheduled: isLightAt(Clock.date) ? "light" : "dark"
  readonly property string mode: state.auto ? scheduled : state.mode
```

[`services/ThemeMode.qml:15-16`](../../config/quickshell/services/ThemeMode.qml#L15-L16)

`scheduled` is a binding on the clock, so the switch happens on the minute without any timer of its own. Picking a mode by hand turns the schedule off.

A new mode needs a new palette, from the same wallpaper. `sync()` compares the mode the last palette was made for (`state.applied`) with the current mode and runs matugen if they differ. Since `applied` is saved, a laptop that slept through the switch time regenerates as soon as it wakes.

The mode also goes beyond yurice's own apps:

```qml
    Quickshell.execDetached(["dconf", "write", "/org/gnome/desktop/interface/color-scheme", light ? "'prefer-light'" : "'prefer-dark'"]);
    Quickshell.execDetached(["dconf", "write", "/org/gnome/desktop/interface/gtk-theme", light ? "'adw-gtk3'" : "'adw-gtk3-dark'"]);
```

[`services/ThemeMode.qml:102-103`](../../config/quickshell/services/ThemeMode.qml#L102-L103)

`color-scheme` is the setting GTK 4 apps, browsers and most Electron apps read to pick light or dark. The GTK 3 theme covers older apps.

## Upscaling

Wallpapers from the internet are often smaller than your screen. The wallpaper library offers an upscale button on any image smaller than 3840×2160, handled by [`services/WallpaperTools.qml`](../../config/quickshell/services/WallpaperTools.qml) with [`scripts/upscale-wallpaper.sh`](../../config/quickshell/scripts/upscale-wallpaper.sh).

Upscales run one at a time from a queue, since each one uses the GPU heavily. The service picks the smallest factor that reaches 4K (2×, 3× or 4×) and runs `realesrgan-ncnn-vulkan` with the `realesr-animevideov3` model, which is made for drawn art. Progress comes from the tool's stderr, where it prints lines like `42.50%`, and the wallpaper island shows it as its label.

The script is careful with your files. It works in a temporary folder, checks the result isn't much darker than the input, which would mean the output is corrupted, resizes down to 4K if the model overshot, and only then moves the original to a hidden `.originals` folder next to it and puts the new PNG in its place. If anything fails, the original stays untouched. When it succeeds, the safe mark moves to the new file, and if it was the current wallpaper, the new one is set.

Deleting a wallpaper from the library moves it to the trash with [`scripts/trash.sh`](../../config/quickshell/scripts/trash.sh), following the freedesktop trash format, so your file manager can restore it.

## The greeter copy

The login screen runs before you've logged in, as a different user, and can't read your home folder. [`services/WallpaperPublish.qml`](../../config/quickshell/services/WallpaperPublish.qml) copies what it needs to `/var/lib/yurice/users/$USER/`, a folder the installer creates for you, readable by everyone and writable by you:

```qml
    publisher.command = ["sh", Paths.scripts + "/publish-wallpaper.sh", Wallpapers.current, avatar, Theme.paletteFile, `${size.width}x${size.height}`, cacheFile, publishDir];
```

[`services/WallpaperPublish.qml:29`](../../config/quickshell/services/WallpaperPublish.qml#L29)

[`scripts/publish-wallpaper.sh`](../../config/quickshell/scripts/publish-wallpaper.sh) resizes the wallpaper to your screen size, saves that as `~/.cache/yurice/wallpaper-cache.jpg`, and copies it, a 256 pixel avatar and `colors.json` into the shared folder. Each file is written under a temporary name and then renamed, so the greeter never reads half a file.

It runs one second after the last change to the wallpaper, the avatar or the colors, so a burst of changes publishes once. The resized cache is reused by the wallpaper windows and the session intro, since a JPEG at screen size loads much faster than the original. A path file next to it remembers which wallpaper it was made from, so it's only rebuilt when the wallpaper changes.

## The session intro and outro

When you log in, [`SessionIntro.qml`](../../config/quickshell/modules/wallpaper/SessionIntro.qml) covers every screen with a blurred, slightly zoomed-in copy of your wallpaper. Once the wallpaper has loaded on every screen, it sharpens and settles to its normal size, and then the cover fades away. It runs once per login. A marker file in `$XDG_RUNTIME_DIR` stops it from replaying when you reload the shell.

[`SessionOutro.qml`](../../config/quickshell/modules/wallpaper/SessionOutro.qml) is the reverse for logging out: a scrim fades in over every screen, and only when it's fully dark does `Session` tell niri to quit. Chapter 20 covers the greeter and lock screen that share this look.

Next are the panels that drop down from the middle of the bar.
