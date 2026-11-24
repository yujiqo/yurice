# 16. Two modes

yurice is made for weebs first, which means anime wallpapers, an anime avatar and a danbooru island on the bar. That's not always what you want on screen, say in a meeting, on a shared screen, or at work. So the desktop has two modes, and the second one hides a set of things you choose. They're called "Weeb" and "Normie" by default, and you can rename them to anything up to 16 characters: personal and work, regular and focus, casual and pro.

`Mod+Shift+S` or a right click on the mode island switches between them. `Mod+S` or a left click opens the mode panel.

This chapter is short because the work was already done. The mode is one service, and everything else just reads it.

## WeebMode

[`services/WeebMode.qml`](../../config/quickshell/services/WeebMode.qml) stores its state in `~/.local/state/yurice/weeb.json`, using the `FileView` + `JsonAdapter` pattern from chapter 7:

```qml
    JsonAdapter {
      id: state
      property string mode: "weeb"
      property string primaryName: ""
      property string secondaryName: ""
      property bool hideWallpapers: true
      property bool hideDanbooru: true
      property bool hideAnimeFilter: true
      property bool hideAdultFilters: true
      property bool hideAvatar: true
      property list<string> hideIslands: []
    }
```

[`services/WeebMode.qml:98-109`](../../config/quickshell/services/WeebMode.qml#L98-L109)

Those defaults are the whole policy for a fresh install. The second mode hides unsafe wallpapers, the danbooru island, the anime category and the adult filters in wallpaper search, and your avatar. Every other island stays.

The `hide*` flags say what the second mode would hide. They don't do anything on their own. What other code reads is a set of `hides*` properties, which combine a flag with the current mode:

```qml
  readonly property bool hidesWallpapers: normie && state.hideWallpapers
  readonly property bool hidesDanbooru: hidesIsland("danbooru")
  readonly property bool hidesAnimeFilter: normie && state.hideAnimeFilter
  readonly property bool hidesAdultFilters: normie && state.hideAdultFilters
  readonly property bool hidesAvatar: normie && state.hideAvatar
  readonly property string avatar: hidesAvatar ? Settings.normieAvatarPath : Settings.avatarPath
```

[`services/WeebMode.qml:21-26`](../../config/quickshell/services/WeebMode.qml#L21-L26)

So a service never asks "which mode am I in?". It asks "should I hide my thing right now?", and the answer changes the moment you switch modes. That keeps the mode logic in one file. If a third kind of thing ever needs hiding, it's one more flag and one more `hides*` here.

The names work the same way. `primaryLabel` is your custom name or "Weeb", and everything that shows the mode's name reads it, including the island label, the mode panel, the settings page and the island list (`"${WeebMode.primaryLabel} / ${WeebMode.secondaryLabel} mode"` in [`Islands.qml`](../../config/quickshell/services/Islands.qml#L37)).

## Who reads it

Each `hides*` property has one or two readers, and each reader does its own small part.

Wallpapers. [`Wallpapers.qml`](../../config/quickshell/services/Wallpapers.qml) keeps a list of files marked safe, in `wallpaper-safe.json`. While `hidesWallpapers` is true, its `wallpapers` list only has safe files, and it remembers a separate current wallpaper for this mode in `normiePath`. Switching modes switches between the two wallpapers, and with them the whole color scheme. You mark a wallpaper safe by right-clicking it in the wallpaper library, and wallhaven downloads that are SFW and not anime are marked safe automatically (chapter 14). With no safe wallpapers at all, the library says "No safe wallpapers yet, mark some in Weeb mode".

Islands. [`Islands.shown`](../../config/quickshell/services/Islands.qml#L79-L89) calls `WeebMode.hidesIsland(id)` (chapter 10), so hidden islands slide off the bar through their `BarSlot`s and their panels refuse to open. Danbooru is stored as its own flag, `hideDanbooru`, instead of in the `hideIslands` list, and `islandHidden` handles both.

Search filters. `WallSearch` drops the anime category bit and forces purity to SFW, and the panel hides those chips. `Danbooru` adds `rating:g` to every search and hides the safe-only toggle. Both reset their current results when the mode switches, so the grid can't still be showing results from the other mode.

Avatar. `WeebMode.avatar` picks between `weeb.jpg` and `normie.jpg`, and the user island, the lock screen and the published greeter avatar all read it.

## The mode panel

[`modules/bar/WeebPanel.qml`](../../config/quickshell/modules/bar/WeebPanel.qml) has a `ChoiceGroup` with the two modes, and above it three tabs: "Content" for the four content flags, "Islands" for which islands to hide, and "Names" for renaming the modes. Each row is a `SwitchRow` or a `TextField` that calls one function on `WeebMode`, which writes the file.

The tabs sit inside a `Collapse`:

```qml
  Collapse {
    width: parent.width
    shown: !WeebMode.normie
    ...
```

[`modules/bar/WeebPanel.qml:100-102`](../../config/quickshell/modules/bar/WeebPanel.qml#L100-L102)

They're only shown in the first mode. In the second mode, the panel is just the switch back. Whoever is looking at your screen can't open the panel and see a list of what's hidden, or turn something back on, without switching modes first.

## Startup

Modes have one tricky moment, which chapter 10 touched on. `weeb.json` is read asynchronously, so for a moment after startup the adapter holds its defaults, which say "first mode". If you were in the second mode, everything would briefly show and then hide: islands would animate away, and the wallpaper could flash.

`WeebMode.loaded` becomes true once the file has been read or found missing. `Islands.ready` and `Wallpapers.ready` wait for it, `BarSlot` jumps instead of animating until then, and `Wallpapers.current` stays empty until it's known which wallpaper to show. The shell starts directly in the right mode.

That's the end of Part III. Everything on the bar is covered. Part IV is about what lives outside it: the wallpaper and its colors, the launcher, screenshots, and the lock screen.
