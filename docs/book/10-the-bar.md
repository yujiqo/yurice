# 10. The bar

Part III builds the thing you look at most. This chapter covers the bar as a whole: the window it lives in, how the islands are laid out, how some of them come and go, and how the bar gets out of the way. The next chapter opens up a single island.

## One bar per screen

From chapter 2 you know `shell.qml` makes a `Bar` for every monitor with `Variants`. [`modules/bar/Bar.qml`](../../config/quickshell/modules/bar/Bar.qml) is a `PanelWindow` that receives its screen as `modelData`:

```qml
PanelWindow {
  id: root

  required property ShellScreen modelData
  property string dropdown: ""
  ...
```

[`modules/bar/Bar.qml:9-13`](../../config/quickshell/modules/bar/Bar.qml#L9-L13)

`dropdown` is the most important property in the bar. It holds the name of the panel that's open on this screen, or `""` when none is. Every island reads it to decide whether it's the one that should be open. Chapter 9 showed how keybinds set it through `Panels`. Clicks set it through `request`:

```qml
  function request(name) {
    dropdown = dropdown === name ? "" : name;
  }
```

[`modules/bar/Bar.qml:46-48`](../../config/quickshell/modules/bar/Bar.qml#L46-L48)

Clicking an island asks for its panel, and clicking it again closes it. Since there's only one `dropdown` per bar, opening one panel closes any other on the same screen for free.

## A tall, mostly empty window

Here's the window's shape:

```qml
  screen: modelData
  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: Math.min(Theme.barMarginTop + Theme.barHeight + Theme.dropdownMaxHeight + Theme.toastAreaHeight, modelData.height)
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: Theme.barMarginTop + Theme.barHeight
  WlrLayershell.keyboardFocus: dropdown !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  color: "transparent"
```

[`modules/bar/Bar.qml:95-105`](../../config/quickshell/modules/bar/Bar.qml#L95-L105)

The bar itself is 30 pixels high plus a 10 pixel margin, and that's all `exclusiveZone` reserves, so tiled windows start just below it. The window is much taller, though: room for the bar, a panel up to 520 pixels high (`dropdownMaxHeight`), and 420 pixels of toasts below it, all inside a transparent surface.

The reason is that panels grow out of the islands. If the window were only as tall as the bar, every panel opening would have to resize a Wayland surface in step with an animation, and that never looks smooth. With a fixed tall window, a panel is just an item getting taller inside it.

A transparent window still catches clicks, though. Without help, the empty area under the bar would swallow every click meant for the windows below. That's what the mask is for.

## The input mask

```qml
  mask: Region {
    item: workspaces

    Region {
      item: leftRow
    }
    Region {
      item: rightRow
    }
    Region {
      x: toasts.x
      y: toasts.y
      width: toasts.visible ? toasts.width : 0
      height: toasts.contentHeight
    }
  }
```

[`modules/bar/Bar.qml:107-122`](../../config/quickshell/modules/bar/Bar.qml#L107-L122)

A `Region` tells the compositor which parts of the window accept input. Everything else passes straight through to whatever is underneath. The region here is the union of the three groups of islands and the visible toasts. Since the regions follow items, and an island grows into its panel, an open panel is clickable automatically and the mask shrinks again when it closes.

## Three groups

The bar has three groups of islands. The workspaces sit in the center, anchored to the top. The left `Row` holds the user island, media, theme, wallpapers, danbooru, mode and weather. The right `Row` holds connectivity, levels (volume and brightness), battery and the clock.

```qml
  Row {
    id: leftRow
    anchors.left: parent.left
    anchors.leftMargin: Theme.barMargin
    anchors.top: parent.top
    anchors.topMargin: Theme.barMarginTop
    spacing: Theme.barGap
    opacity: 1 - hide.value
    transform: Translate {
      y: root.hideOffset
    }

    UserIsland {
      host: root
    }
    BarSlot {
      shown: !Islands.hidden.includes("media")
      animate: Islands.ready

      MediaIsland {
        host: root
      }
    }
    ...
```

[`modules/bar/Bar.qml:145-167`](../../config/quickshell/modules/bar/Bar.qml#L145-L167)

Every island gets `host: root`. That's how an island reaches the bar's `dropdown` and `request`, and it's the only thing an island knows about the bar.

The center island is a little unusual. [`Workspaces.qml`](../../config/quickshell/modules/bar/Workspaces.qml) shows the workspace dots, and it also owns the panels that don't belong to any other island: the launcher, the clipboard, the power menu, the cheatsheet and the screenshot panel. They all drop down from the middle of the screen.

## Islands that come and go

Most islands can be hidden, either by you in the settings or by the current mode (chapter 16). Some also hide themselves: the media island only shows while a player is running, and the battery island only on machines with a battery. One service answers the question "should this island be on the bar?" for all of them.

[`services/Islands.qml`](../../config/quickshell/services/Islands.qml) starts with a plain list:

```qml
  readonly property var list: [
    {
      id: "media",
      icon: "music_note",
      label: "Media",
      panels: ["media"]
    },
    ...
    {
      id: "connectivity",
      icon: "wifi",
      label: "Wi-Fi and Bluetooth",
      panels: ["wifi", "bluetooth"]
    },
    ...
  ]
```

[`services/Islands.qml:9-70`](../../config/quickshell/services/Islands.qml#L9-L70)

That list drives the settings page and the mode panel, so a new island added here shows up in both. Then each island is checked in one function:

```qml
  function shown(id) {
    if (!enabled(id))
      return false;
    if (WeebMode.hidesIsland(id))
      return false;
    if (id === "media")
      return Media.active !== null;
    if (id === "battery")
      return Battery.available;
    return true;
  }
```

[`services/Islands.qml:79-89`](../../config/quickshell/services/Islands.qml#L79-L89)

The bar only ever reads `Islands.hidden`, the list of ids that fail that check. Note that the user and workspaces islands aren't in the list at all, so they can't be hidden.

`panels` maps each island to the panels it owns. That's what lets `Panels.open` refuse `Mod+N` when the connectivity island is hidden (chapter 9), and the bar closes an open panel the moment its island disappears:

```qml
  Connections {
    target: Islands
    function onHiddenChanged() {
      if (!Islands.panelShown(root.dropdown))
        root.dropdown = "";
    }
  }
```

[`modules/bar/Bar.qml:79-85`](../../config/quickshell/modules/bar/Bar.qml#L79-L85)

### BarSlot

When an island appears or disappears, its neighbours shouldn't jump. [`components/BarSlot.qml`](../../config/quickshell/components/BarSlot.qml) is a `Reveal` made for whole islands:

```qml
Item {
  id: root

  property bool shown: true
  property bool animate: true
  default property alias content: holder.data
  readonly property real progress: spring.progress

  implicitWidth: (holder.width + Theme.barGap) * spring.value - Theme.barGap
  implicitHeight: holder.height
  visible: spring.value > 0.001

  onShownChanged: {
    if (animate)
      spring.target = shown ? 1 : 0;
    else
      spring.jump(shown ? 1 : 0);
  }

  Spring {
    id: spring
    Component.onCompleted: jump(root.shown ? 1 : 0)
  }

  Item {
    id: holder
    width: childrenRect.width
    height: childrenRect.height
    opacity: root.progress
    scale: 0.8 + 0.2 * root.progress
  }
}
```

The width includes the gap after the island, so a hidden slot takes up exactly zero space in the `Row`: the `- Theme.barGap` cancels out the row's own spacing. The island fades and grows from 80% while its neighbours slide over.

`animate` is there because of a bug. The mode is read from a file, and for a moment after startup `WeebMode` still has its defaults. Without `animate: Islands.ready`, reloading the shell in the second mode made islands visibly animate away on every start ("fix danbooru island dissapear after reloading shell in normie mode"). Until the state is loaded, slots jump instead of animating.

## Getting out of the way

When a window covers the whole screen, the bar hides. Chapter 5 showed the spring, and the rest is in the groups: each one has `opacity: 1 - hide.value` and a `Translate` by `hideOffset`, so all three slide up and fade together. An open panel also closes when the bar starts hiding:

```qml
  onCoveredChanged: {
    if (covered)
      dropdown = "";
  }
```

[`modules/bar/Bar.qml:22-25`](../../config/quickshell/modules/bar/Bar.qml#L22-L25)

Note what doesn't change: the exclusive zone. Tiled windows keep their space at the top, so the screen doesn't reflow every time a window goes full size and back. The bar only hides from windows that already cover that space, like fullscreen video.

## Keeping the bar honest

Since there's one `dropdown` per screen, the bar is also where it's kept in step with everything else that can open a panel: `Panels` for keybinds, `Launcher` for the launcher and clipboard, `Session` for the power menu, and `Displays`, which closes the user panel while it asks you to confirm a new display layout. Each of those is a short handler near the top of `Bar.qml`. Chapter 9 walked through the `Panels` one, and the others follow the same shape.

The bar is now a row of islands that can appear, disappear and hide. Next, what happens inside one when you click it.
