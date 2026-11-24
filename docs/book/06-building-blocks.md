# 6. Building blocks

Open any two panels in yurice, battery and weather say, and they look like siblings: the same big header with an icon, the same rounded cards, the same rows of icon, label and value, the same switches. Nobody was careful twice. Both are built from the same dozen components.

This chapter goes through those components and the small keyboard contract they all follow, then reads a complete real panel, which by that point is almost plain English.

## Card: a surface to put things on

```qml
Rectangle {
  id: root

  property real padding: 4
  property real spacing: 0
  default property alias content: column.data

  width: parent.width
  implicitHeight: column.implicitHeight + padding * 2
  height: implicitHeight
  radius: Theme.menuItemRadius
  color: Theme.surfaceContainer

  Column {
    id: column
    y: root.padding
    width: parent.width
    spacing: root.spacing
  }
}
```

[`components/Card.qml`](../../config/quickshell/components/Card.qml)

That's the whole thing: a rounded `surfaceContainer` rectangle, one step lighter than the panel behind it, with a `Column` inside. It fills its parent's width and grows to fit its content, and thanks to `default property alias` (from the last chapter) you just put rows inside it.

## PanelHeader: the top of every panel

Every panel opens with a large icon, a big title, a smaller subtitle, and sometimes a few buttons on the right:

```qml
Item {
  id: root

  property string icon: ""
  property color iconColor: Theme.primary
  property string title: ""
  property string subtitle: ""
  property bool smoothTitle: false
  default property alias trailing: trailingRow.data
  ...
}
```

[`components/PanelHeader.qml`](../../config/quickshell/components/PanelHeader.qml)

The default property goes to the trailing row, so anything you nest inside a `PanelHeader` lines up on its right edge. `smoothTitle` passes through to the title's `Label`, so a title that changes, like a percentage, can animate its width (chapter 4).

## Rows

Three row types cover almost every line in every panel:

| Component                                                       | Looks like                                | For                      |
| --------------------------------------------------------------- | ----------------------------------------- | ------------------------ |
| [`InfoRow`](../../config/quickshell/components/InfoRow.qml)     | `[icon]  label ……………… value`              | read-only facts          |
| [`SwitchRow`](../../config/quickshell/components/SwitchRow.qml) | `[icon]  label ……………… [switch]`           | on/off settings          |
| [`MenuItem`](../../config/quickshell/components/MenuItem.qml)   | `[icon]  title / subtitle ……… [trailing]` | things you pick or click |

`SwitchRow` shows how small composition can be. It's an `InfoRow` with a `Switch` added on the right:

```qml
InfoRow {
  id: root

  property bool checked: false
  property bool dimmed: false

  signal toggled

  width: parent.width
  value: ""

  Switch {
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    checked: root.checked
    opacity: root.dimmed ? 0.4 : 1
    onToggled: root.toggled()
  }
}
```

[`components/SwitchRow.qml`](../../config/quickshell/components/SwitchRow.qml)

The "unify section titles and key rows" commit changed a handful of these files, and every panel followed.

[`SectionTitle`](../../config/quickshell/components/SectionTitle.qml) is the small, spaced-out, uppercase heading above a group of rows. [`EmptyState`](../../config/quickshell/components/EmptyState.qml) is the centered icon and message shown when a list has nothing in it.

## Inputs

### Switch

[`components/Switch.qml`](../../config/quickshell/components/Switch.qml) is the Material 3 style toggle. The knob is small and outlined when off, larger and filled when on, and slides across. Each visual property gets its own `Behavior`, so color, size and position animate together:

```qml
  Rectangle {
    property real size: root.checked ? 18 : 12
    property real center: root.checked ? root.width - 13 : 13
    ...
    Behavior on center { NumberAnimation { duration: Theme.animMove; easing.type: Theme.easeOut } }
    Behavior on size { NumberAnimation { duration: Theme.animMove; easing.type: Theme.easeOut } }
    Behavior on color { ColorAnimation { duration: Theme.animColor } }
  }
```

Animating `center` instead of `x` is the subtle part. When the knob grows and moves at the same time, animating `x` makes it wobble, because `x` depends on `size`. Animating the center and deriving `x` from it keeps the knob on track. That was the "fix switch toggle animation" commit.

### Slider

[`components/Slider.qml`](../../config/quickshell/components/Slider.qml) handles volume and brightness. Chapter 5 covered its spring.

The track is split by the handle, with a small gap on each side. The filled part is the accent color and the rest is `surfaceContainerHighest`. The corners next to the handle are less rounded (`topRightRadius: 3`), which reads as the bar continuing behind the handle.

The slider never sets its own value. It emits `moved(value)` and the owner decides what to do. The volume panel passes it to the audio service, the service changes the real volume, and the new volume flows back into `value` through a binding. With one source of truth, the slider can't drift away from the actual system volume.

Scrolling works with both mouse wheels and touchpads. Wheel deltas are added up into whole 120-unit notches, so a touchpad's many tiny deltas don't fire hundreds of steps.

### ChoiceGroup

A row of options where one is selected, like power profiles or theme modes. The selected option widens to show its label (a `Reveal`) and the others shrink to an icon. Corner radii change so the group reads as one connected pill:

```qml
        width: active ? root.selectedWidth : root.compactWidth
        topLeftRadius: first ? outer : inner
        bottomLeftRadius: first ? outer : inner
        topRightRadius: last ? outer : inner
        bottomRightRadius: last ? outer : inner
```

[`components/ChoiceGroup.qml`](../../config/quickshell/components/ChoiceGroup.qml)

### TextField

[`components/TextField.qml`](../../config/quickshell/components/TextField.qml) is a search box with an optional leading icon, placeholder, hint and clear button. The interesting part is the keys. A text field normally eats every key, which would trap keyboard users inside it, so this one hands navigation keys back out. `↓` or `Tab` emits `navigate(1)`, and `↑` or `Shift+Tab` emits `navigate(-1)`; the launcher uses this to move through results while you keep typing. `Esc` emits `canceled`. With `escapeLeaves: true`, `Esc` and the arrows move focus out of the input and back to the panel's normal navigation.

### Buttons and lists

[`IconButton`](../../config/quickshell/components/IconButton.qml) is a round, icon-only button, and [`Chip`](../../config/quickshell/components/Chip.qml) is a small pill that can be selected. [`MenuList`](../../config/quickshell/components/MenuList.qml) is a `ListView` with the theme's spacing, a maximum height, a [`Scrollbar`](../../config/quickshell/components/Scrollbar.qml), and `followCurrent` to keep the selected row on screen during keyboard navigation.

## The keyboard contract

Look at what every interactive component above has in common:

```qml
  activeFocusOnTab: true
  ...
  FocusRing {}
```

and usually one of:

```qml
  function keyActivate() { … }        // what Enter/Space does
  function keyAdjust(direction) { … } // what ←/→ does (sliders)
  signal clicked                       // used when there's no keyActivate
```

That's the entire contract between a component and the keyboard:

1. `activeFocusOnTab: true` says "I'm focusable". The panel's navigation (chapter 12) collects every visible item with this flag and moves between them with `Tab`, `hjkl` or the arrows.
2. `FocusRing {}` shows where focus is.
3. `keyActivate()` or `clicked()` is what `Enter` and `Space` call. The panel tries `keyActivate` first, then falls back to `clicked`.
4. `keyAdjust(±1)` is what `←` and `→` call, if the item has it.

A component never listens for `Enter` itself. It only says what activating it means, and the panel does the rest. Any new component that follows these four rules works with the keyboard everywhere, with no extra code.

## Reading a real panel

Here's the battery panel, mostly in full:

```qml
Column {
  id: root

  readonly property var profiles: { ... saver, balanced, and performance if available ... }

  spacing: 8

  PanelHeader {
    icon: Battery.icon
    iconColor: Battery.color
    title: Battery.percent + "%"
    subtitle: Battery.status

    Chip {
      implicitWidth: 40
      implicitHeight: 40
      icon: "coffee"
      selected: Caffeine.active
      onClicked: Caffeine.toggle()
    }
  }

  Item { ... the charge bar, with a tick at the charge limit ... }

  Card {
    InfoRow {
      width: parent.width
      icon: "bolt"
      label: Battery.charging ? "Charging at" : "Power draw"
      value: Battery.rate > 0 ? Battery.rate.toFixed(1) + " W" : "—"
    }
    ...
    InfoRow {
      width: parent.width
      visible: Battery.cycles >= 0
      icon: "autorenew"
      label: "Cycles"
      value: Battery.cycles
    }
    ...
  }

  ChoiceGroup {
    width: parent.width
    options: root.profiles
    current: PowerProfiles.profile
    onSelected: value => PowerProfiles.profile = value
  }
}
```

[`modules/bar/BatteryPanel.qml`](../../config/quickshell/modules/bar/BatteryPanel.qml)

Notice what's missing. There are no colors except roles and `Battery.color`, no font sizes, radii or hover handling, no key handling, and no animation code apart from the charge bar's width `Behavior`.

The panel says what to show, and the building blocks decide how it looks and behaves. The caffeine chip, the info rows and the power profile buttons are all keyboard-reachable without the panel writing a line for it.

`Battery`, `Caffeine` and `PowerProfiles` are the other half: services, singletons that talk to the system.

That's the end of Part I. You now know every layer that draws things. Part II is about the layer that knows things: how the shell finds out what your wifi, your volume and your windows are doing.
