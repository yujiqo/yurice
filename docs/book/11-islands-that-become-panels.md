# 11. Islands that become panels

Click the battery island and it doesn't open a popup somewhere. The pill itself grows: wider, taller, its corners rounding out, until it is the battery panel. Click away and it shrinks back into a pill. Every island in yurice does this, and all of them get it from one file, [`components/Island.qml`](../../config/quickshell/components/Island.qml).

This chapter builds that file in the order you'd write it: a pill, then the panel inside it, then the morph between them, then the details that make it feel right.

## Step 1: a pill

An island starts as a rounded rectangle with a `Row` inside. Its content goes into the row through a default property, the same trick as `Card` and `Reveal`:

```qml
Rectangle {
  id: root

  default property alias content: row.data
  readonly property bool hovered: hover.hovered
  readonly property bool expanded: hovered || open
  property real padding: Theme.pillPadding
  property real spacing: Theme.pillSegmentGap
  property bool clickable: false
  ...
```

[`components/Island.qml:6-15`](../../config/quickshell/components/Island.qml#L6-L15)

`expanded` is true while you hover the island or its panel is open. Islands use it to show extra detail: the clock reveals the date, the battery shows the power profile, the levels island shows percentages.

The simplest island is a whole file of configuration. Here's the theme island in full:

```qml
IconIsland {
  id: root

  panels: ({
      theme: themePanel
    })
  panelWidth: 340
  icon: "contrast"
  label: ThemeMode.label
  smoothLabel: true
  onClicked: mouse => mouse.button === Qt.RightButton ? ThemeMode.toggle() : request("theme")

  Component {
    id: themePanel

    ThemePanel {}
  }
}
```

[`modules/bar/ThemeIsland.qml`](../../config/quickshell/modules/bar/ThemeIsland.qml)

[`IconIsland`](../../config/quickshell/components/IconIsland.qml) is an `Island` with an icon and a label that reveals on hover. It can also swap its icon for a spinner while `working` is true, which the wallpaper and danbooru islands use during searches and downloads. A left click opens the panel and a right click flips the theme directly. Most islands have a right-click shortcut like this.

## Step 2: which panel, and when

An island declares its panels as a map from name to `Component`:

```qml
  property var host: null
  property var panels: ({})
  readonly property var panelNames: Object.keys(panels)
  property string current: host?.dropdown ?? ""
  property bool open: panelNames.includes(current)
  ...
  property Component panel: panels[current] ?? null
```

[`components/Island.qml:17-24`](../../config/quickshell/components/Island.qml#L17-L24)

There's no "open" function anywhere. The island looks at the bar's `dropdown` through `host`, and it's open whenever that names one of its panels. Most islands own one panel. The connectivity island owns two, `wifi` and `bluetooth`, and the center island owns five.

Going the other way, an island has two signals that it forwards to the bar:

```qml
  onRequest: name => root.host?.request(name)
  onDismissed: {
    if (root.host)
      root.host.dropdown = "";
  }
```

[`components/Island.qml:41-45`](../../config/quickshell/components/Island.qml#L41-L45)

So `request("theme")` in the theme island really calls `Bar.request("theme")`, which sets `dropdown`, which makes `open` true. The state lives in one place, and the island just follows it.

The panels are `Component`s, not objects. A component is a recipe that hasn't been made yet, and the island only makes the current one, through a `Loader`:

```qml
    Loader {
      id: panelLoader
      width: parent.width
      active: root.open || openSpring.value > 0.01
      sourceComponent: root.shownPanel
      focus: true
    }
```

[`components/Island.qml:333-339`](../../config/quickshell/components/Island.qml#L333-L339)

The panel exists while the island is open and while it's still shrinking closed, and not a moment longer. This is the "only exists while it's open" idea from chapter 2, and it shapes how panels are written. A panel can start work in `Component.onCompleted` and stop it in `Component.onDestruction`, and that's exactly the panel's lifetime. The Wi-Fi panel turns on network scanning when it's created and turns it off when it's destroyed, so the laptop only scans while you're looking at the list.

## Step 3: the morph

Now the part you see. One spring goes from 0 (pill) to 1 (panel), and the island's size and shape are formulas of it:

```qml
  implicitWidth: compactWidth + (openWidth - compactWidth) * openSpring.value
  implicitHeight: Theme.pillHeight + panelHeight.value * openSpring.value
  radius: Theme.pillHeight / 2 + (Theme.panelRadius - Theme.pillHeight / 2) * progress
  color: Theme.surface
  clip: true
```

[`components/Island.qml:196-200`](../../config/quickshell/components/Island.qml#L196-L200)

The width goes from the pill's own width to `panelWidth`. The height goes from one pill to a pill plus the panel. The radius goes from a full pill (half the height) to the panel's 22 pixels. `clip: true` hides the panel while there isn't room for it yet. It's the "boolean becomes a spring" pattern from chapter 5, with three properties hanging off one number.

There are two springs, not one:

```qml
  Spring {
    id: openSpring
    target: root.open && root.shownPanel ? 1 : 0
  }

  Spring {
    id: panelHeight
    target: panelLoader.item ? panelLoader.item.implicitHeight + Theme.panelPadding : 0
    onTargetChanged: {
      if (openSpring.value < 0.01)
        snap();
    }
  }
```

[`components/Island.qml:279-291`](../../config/quickshell/components/Island.qml#L279-L291)

`openSpring` is open or closed. `panelHeight` follows the panel's own height, because panels change height while open: a Wi-Fi list fills in, a section expands. With a separate spring, those changes glide too. The `snap()` makes sure the first height is known before the island starts opening, so it doesn't grow toward the wrong size.

The panel's content fades in over the second half of the morph:

```qml
    opacity: Math.max(0, root.progress * 2 - 1) * root.switchFade
```

[`components/Island.qml:325`](../../config/quickshell/components/Island.qml#L325)

While the progress is below 0.5 the content stays invisible, so you never see text squeezed into a half-grown pill. From 0.5 to 1 it fades in.

## Step 4: switching panels inside one island

The connectivity island holds Wi-Fi and Bluetooth. If Wi-Fi is open and you click the Bluetooth segment, closing and reopening the island would look silly. Instead, the content switches in place:

```qml
  onPanelChanged: {
    if (!panel)
      return;
    if (shownPanel && shownPanel !== panel && open && progress > 0.5) {
      pendingPanel = panel;
      Qt.callLater(startSwitch);
    } else {
      switchAnim.stop();
      switchFade = 1;
      switchSlide = 0;
      shownPanel = panel;
      shownIndex = panelIndex;
    }
  }
```

[`components/Island.qml:204-217`](../../config/quickshell/components/Island.qml#L204-L217)

`panel` is what should be shown, and `shownPanel` is what the loader actually shows. If the island is already mostly open, the switch runs a fade-and-slide sequence, the same shape as `TabTransition` from chapter 5. Otherwise the new panel is shown right away. Meanwhile `panelHeight` springs to the new panel's height, so the island resizes smoothly between the two.

## Step 5: closing on its own

A panel opened by mouse closes when the mouse leaves, after a short grace period:

```qml
  Timer {
    interval: Theme.closeGrace
    running: root.open && !root.hovered && !root.holding
    onTriggered: root.dismissed()
  }
```

[`components/Island.qml:346-350`](../../config/quickshell/components/Island.qml#L346-L350)

The timer runs while the island is open and the mouse is elsewhere. If the mouse comes back within 400 ms, `running` turns false and the timer resets. That grace is what lets you move diagonally from an island into its panel without it snapping shut when the cursor clips a corner.

Some panels must not close like that, and `holding` collects the reasons:

```qml
  readonly property bool holding: hold || (panelLoader.item?.keepOpen ?? false) || (open && Panels.isOpen)
```

[`components/Island.qml:33`](../../config/quickshell/components/Island.qml#L33)

An island can set `hold` itself. The center island always does, because the launcher is used from the keyboard and your mouse could be anywhere. A panel can set `keepOpen` while it's busy: the Wi-Fi panel while it asks for a password, the media panel while you drag the seek bar, the user panel while you crop an avatar. And a panel opened from the keyboard through `Panels` stays open until you close it, since you didn't hover anything to open it.

## Step 6: the press

One last touch. Pressing an island scales it down a little, and less when it's open:

```qml
  transformOrigin: Item.Top
  scale: mouse.pressed || held ? (open ? 0.98 : 0.95) : 1
```

[`components/Island.qml:201-202`](../../config/quickshell/components/Island.qml#L201-L202)

`transformOrigin: Item.Top` keeps the top edge in place, so the island shrinks toward the bar and not away from it. Islands made of several segments set `held` from their segments, so pressing the volume part of the levels island presses the whole island.

## An island that opens itself

The levels island shows how far this goes with no changes to `Island.qml`. When you press a volume key, the volume panel opens for a moment as an on-screen display and then closes:

```qml
  function flash(kind) {
    if (!ready || current === kind)
      return;
    osd = kind;
    osdTimer.restart();
  }

  open: shown !== ""
  hold: osd !== ""
  ...
  panel: panels[shown] ?? null
```

[`modules/bar/LevelsIsland.qml:23-37`](../../config/quickshell/modules/bar/LevelsIsland.qml#L23-L37)

`Audio.percent` changing calls `flash("volume")`. The island overrides `open` to also be true while `osd` is set, which is for 1.5 seconds, and holds itself open for that time. It never touches the bar's `dropdown`, so no other panel closes because of it. If you hover it during the flash, it turns into a real open panel. The `ready` flag is set by a one-second timer at startup, so the first volume reading doesn't flash the panel every time the shell starts.

That's the whole island. Next is the other way to drive it: the keyboard.
