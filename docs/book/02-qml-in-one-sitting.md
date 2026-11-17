# 2. QML in one sitting

You can't read yurice without reading QML, but if you were learning full QML and Qt framework first, you'd spend a lot of time that you could've used to actually implement something. This chapter covers the dozen ideas the codebase actually uses, in the order you'll run into them. I recommend you to keep opened shell.qml file to try all snippets yourself. For quickstart and installation instructions you can follow official quickshell docs. Return once you have everything to run and write qml code ready.

## A first window

Make a folder `~/.config/quickshell/scratch/` with one file, `shell.qml`:

```qml
import Quickshell
import QtQuick

PanelWindow {
  anchors.top: true
  implicitHeight: 40
  color: "#202020"

  Text {
    anchors.centerIn: parent
    text: "hello, world!"
    color: "white"
  }
}
```

Run it with `qs -p ~/.config/quickshell/scratch`. A dark rectangle appears at the top of the screen, with "hello, world" in the middle.

Reading it top to bottom:

- `import` brings in a module. `QtQuick` has the visual basics (`Text`, `Rectangle`, `Image`…). `Quickshell` has desktop-shell things like windows.
- `PanelWindow { … }` creates an **object** of type `PanelWindow`. Objects nest: the `Text` is a child of the window.
- `anchors.top: true` and `color: …` are **properties**. Every object is a bag of properties.

## Properties and bindings

This is the one idea that makes QML different from everything else:

```qml
text: "hello"                 // an assignment: a fixed value
text: "volume " + volume      // a binding: re-evaluated whenever volume changes
```

When a property's value is an _expression_, QML remembers what that expression read. When any of those inputs change, the expression runs again and the property updates by itself. You never write "when the volume changes, update the label". You write what the label _is_, and QML keeps it true.

yurice utilizes this everywhere. Here's how the bar knows whether a full-size window covers its screen:

```qml
readonly property bool covered: Niri.outputCovered(modelData.name, modelData.width, modelData.height)
```

[`modules/bar/Bar.qml:19`](../../config/quickshell/modules/bar/Bar.qml#L19)

Nobody ever _sets_ `covered`. When niri reports a window change, `Niri`'s data changes, the binding runs again, and `covered` flips.

You can declare your own properties on any object:

```qml
property real value: 0
readonly property bool pressed: mouse.pressed
property alias text: label.text
```

- `property <type> name: value` makes a new property.
- `readonly` means it's computed from a binding and nobody outside can assign it.
- `alias` makes a property that _is_ another object's property. Setting `text` on the outer object sets `label.text`.

> **Assigning breaks bindings.** If code does `covered = true` somewhere, the binding is gone for good. That's why yurice marks computed properties `readonly`.

## ids and parents

`id: label` gives an object a name that other objects in the same file can use. `parent` is the object you're nested in. `root` isn't a keyword. By convention it's the `id` of each file's top object:

```qml
Item {
  id: root
  property alias text: label.text

  Text {
    id: label
    width: root.width
  }
}
```

## Signals and handlers

Objects announce things with **signals**. You react with `on<Signal>` handlers:

```qml
signal toggled            // declare one

MouseArea {
  anchors.fill: parent
  onClicked: root.toggled()   // fire it
}
```

Every property gets a free `<name>Changed` signal too, which is why yurice is full of handlers like `onTargetChanged: …` and `onCoveredChanged: …`.

`Component.onCompleted: …` runs once, when the object has finished being created. It's the closest thing QML has to a constructor.

## Files are types

Save this as `Pill.qml`:

```qml
import QtQuick

Rectangle {
  property string label: ""
  implicitWidth: 80
  implicitHeight: 30
  radius: 15
  Text {
    anchors.centerIn: parent
    text: parent.label
  }
}
```

Now `Pill { label: "hi" }` works in any file that can see it. **A QML file is a type, and its file name is the type's name.** That's what [`components/`](../../config/quickshell/components) is: forty-odd small files, each one a new type the rest of the shell can use.

quickshell treats your config folder as a module called `qs`, and each subfolder as a submodule. That's why yurice files start like this:

```qml
import qs.theme
import qs.components
import qs.services
```

## Layout: anchors, positioners, implicit size

There are three ways to place things, and yurice uses all three:

- **Anchors** pin an edge or the center to another item: `anchors.fill: parent`, `anchors.left: icon.right`, `anchors.verticalCenter: parent.verticalCenter`.
- **Positioners** (`Row`, `Column`) line up their children with a `spacing`.
- **`x`, `y`, `width`, `height`** set by hand, usually through a binding.

Every item also has an **implicit size**: `implicitWidth` and `implicitHeight`, how big it _wants_ to be. Rows, columns and parents read the implicit size when nobody sets a real one. yurice's components almost always set implicit sizes, so they size themselves and can still be overridden.

## Repeater and Loader

`Repeater` stamps out one copy of its child for each item in a model:

```qml
Row {
  Repeater {
    model: ["a", "b", "c"]
    Text {
      required property string modelData
      text: modelData
    }
  }
}
```

`required property … modelData` is how each copy receives its item. You'll see `required property int index` the same way.

`Loader` creates its content **only when needed**:

```qml
Loader {
  active: panelOpen
  sourceComponent: weatherPanel
}
```

When `active` is false, nothing exists: no objects, no memory, no timers. This is a big part of how yurice stays light. A panel's content only exists while it's open.

## Behaviors and animations

Make a property animate whenever it changes:

```qml
Behavior on opacity {
  NumberAnimation { duration: 120 }
}
```

From then on, `opacity: hovered ? 1 : 0` fades instead of snapping. yurice uses `Behavior` for small things like hover colors, and a custom spring (chapter 5) for anything that moves.

## Singletons

A file starting with `pragma Singleton` has exactly one instance, shared by everyone. You use it by its type name, without creating it:

```qml
pragma Singleton
import Quickshell

Singleton {
  property int volume: 50
}
```

Any file can now read `Audio.volume`. The theme and every service in yurice is a singleton. Chapter 3 starts with one.

## `pragma ComponentBehavior: Bound`

Every yurice file starts with this line. It tightens the rules about which `id`s a nested component may see, so mistakes become errors instead of silent bugs. It's also why delegates must declare `required property` for their model data. Just keep it at the top of new files.

## quickshell's own types

QtQuick gives you shapes and text. quickshell adds what a desktop needs. These are the ones yurice uses most:

| Type                       | What it is                                                               |
| -------------------------- | ------------------------------------------------------------------------ |
| `ShellRoot`                | the top of `shell.qml`. Holds everything                                 |
| `PanelWindow`              | a window glued to screen edges, on the Wayland _layer shell_ (see below) |
| `Variants`                 | makes one copy of its child **per item**, usually one per screen         |
| `Singleton`                | base type for singletons                                                 |
| `Process`                  | runs a command, and gives you its output                                 |
| `FileView` + `JsonAdapter` | reads a file, watches it, and maps JSON onto properties                  |
| `IpcHandler`               | exposes functions to `qs ipc call` from the command line                 |
| `Quickshell.screens`       | the list of monitors                                                     |

### The layer shell

Normal windows are placed by the compositor. A shell's windows aren't normal: a bar must hug the top edge, push other windows down, and stay above them. Wayland's **layer shell** protocol lets a program ask for exactly that. Every surface goes on one of four layers (`Background`, `Bottom`, `Top`, `Overlay`), can anchor to edges, and can reserve an _exclusive zone_ that tiled windows avoid.

This is how the bar asks for its spot:

```qml
screen: modelData
anchors {
  top: true
  left: true
  right: true
}
exclusiveZone: Theme.barMarginTop + Theme.barHeight
WlrLayershell.keyboardFocus: dropdown !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
```

[`modules/bar/Bar.qml:95-104`](../../config/quickshell/modules/bar/Bar.qml#L95-L104)

The last line matters for chapter 12. The bar takes keyboard focus only while a panel is open, so your typing never disappears into an invisible bar.

## Reading `shell.qml`

That's enough to read the real entry point in full:

```qml
ShellRoot {
  settings.watchFiles: !SessionLock.sessionLocked

  Component.onCompleted: {
    Keyboard.watch();
    WallpaperPublish.schedule();
  }

  Variants {
    model: Quickshell.screens

    Wallpaper {}
  }

  WallpaperPicker {}

  LockScreen {}

  SessionIntro {}

  SessionOutro {}

  Variants {
    model: Quickshell.screens

    ScreenshotOverlay {}
  }

  Variants {
    model: Quickshell.screens

    DisplayConfirm {}
  }

  Variants {
    model: Quickshell.screens

    Bar {}
  }
}
```

[`shell.qml`](../../config/quickshell/shell.qml)

Line by line:

- **`settings.watchFiles`** turns off hot reload while the screen is locked. Saving a file must never reload the shell and drop your lock.
- **`Component.onCompleted`** starts two background jobs: watching Caps Lock so a toast can tell you when it changes (chapter 18), and publishing your wallpaper for the login screen (chapter 20).
- **A wallpaper, a screenshot overlay, a display-confirm dialog and a bar per screen.** `Variants` makes one of each for every monitor, and hands each copy its screen as `modelData`. That's why `Bar.qml` begins with `required property ShellScreen modelData`. Plug in a monitor and a new bar appears.
- **One picker, one lock screen, one intro and one outro.** These manage their own screens internally.

Order in this file doesn't decide what's on top. The layer each window asks for does.

## Recap

- Properties with **bindings** keep themselves up to date. Don't assign over them.
- **Files are types**, and `qs.*` imports bring in whole folders of them.
- `Loader` creates things only when needed. `Repeater` and `Variants` make copies.
- **Singletons** hold shared state.
- **`PanelWindow`** plus the layer shell is how a shell gets its own place on screen.

Next is the singleton every visible thing depends on: the theme.
