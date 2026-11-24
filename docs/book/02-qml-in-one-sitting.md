# 2. QML in one sitting

You can't read yurice without reading QML, but learning all of QML and Qt first would eat time you could spend building something. This chapter covers the dozen ideas the codebase actually uses, in the order you'll run into them. Keep `shell.qml` open and try the snippets yourself. For installing quickshell, follow the official quickshell docs, and come back once you can run QML.

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

Run it with `qs -p ~/.config/quickshell/scratch`. A dark strip appears at the top of the screen with "hello, world!" in the middle.

`import` brings in a module. `QtQuick` has the visual basics (`Text`, `Rectangle`, `Image`), and `Quickshell` has desktop things like windows. `PanelWindow { … }` creates an object of type `PanelWindow`, and objects nest, so the `Text` is a child of the window. Lines like `anchors.top: true` and `color: …` set properties. Every object is a bag of properties.

## Properties and bindings

This is the one idea that makes QML different from everything else:

```qml
text: "hello"                 // an assignment: a fixed value
text: "volume " + volume      // a binding: re-evaluated whenever volume changes
```

When a property's value is an expression, QML remembers what that expression read. When any of those inputs change, the expression runs again and the property updates by itself. You never write "when the volume changes, update the label". You write what the label is, and QML keeps it true.

yurice uses this everywhere. Here's how the bar knows whether a full-size window covers its screen:

```qml
readonly property bool covered: Niri.outputCovered(modelData.name, modelData.width, modelData.height)
```

[`modules/bar/Bar.qml:19`](../../config/quickshell/modules/bar/Bar.qml#L19)

Nobody ever sets `covered`. When niri reports a window change, `Niri`'s data changes, the binding runs again, and `covered` flips.

You can declare your own properties on any object:

```qml
property real value: 0
readonly property bool pressed: mouse.pressed
property alias text: label.text
```

`property <type> name: value` makes a new property. `readonly` means it's computed from a binding and nobody outside can assign it. `alias` makes a property that is another object's property, so setting `text` on the outer object sets `label.text`.

> Assigning breaks bindings. If code does `covered = true` somewhere, the binding is gone for good. That's why yurice marks computed properties `readonly`.

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

Objects announce things with signals. You react with `on<Signal>` handlers:

```qml
signal toggled            // declare one

MouseArea {
  anchors.fill: parent
  onClicked: root.toggled()   // fire it
}
```

Every property also gets a free `<name>Changed` signal, which is why yurice is full of handlers like `onTargetChanged: …` and `onCoveredChanged: …`.

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
  Text { anchors.centerIn: parent; text: parent.label }
}
```

Now `Pill { label: "hi" }` works in any file that can see it. A QML file is a type, and its file name is the type's name. That's what [`components/`](../../config/quickshell/components) is: forty-odd small files, each one a new type the rest of the shell can use.

quickshell treats your config folder as a module called `qs`, and each subfolder as a submodule. That's why yurice files start like this:

```qml
import qs.theme
import qs.components
import qs.services
```

## Layout: anchors, positioners, implicit size

yurice places things three ways. Anchors pin an edge or the center to another item: `anchors.fill: parent`, `anchors.left: icon.right`, `anchors.verticalCenter: parent.verticalCenter`. Positioners (`Row`, `Column`) line up their children with a `spacing`. And sometimes `x`, `y`, `width` and `height` are set by hand, usually through a binding.

Every item also has an implicit size, `implicitWidth` and `implicitHeight`, which is how big it wants to be. Rows, columns and parents read it when nobody sets a real size. yurice's components almost always set implicit sizes, so they size themselves and can still be overridden.

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

`required property … modelData` is how each copy receives its item. You'll see `required property int index` used the same way.

`Loader` creates its content only when needed:

```qml
Loader {
  active: panelOpen
  sourceComponent: weatherPanel
}
```

When `active` is false, nothing exists: no objects, no memory, no timers. A panel's content only exists while it's open, which is a big part of how yurice stays light.

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

Any file can now read `Audio.volume`. The theme and every service in yurice are singletons. Chapter 3 starts with one.

## `pragma ComponentBehavior: Bound`

Every yurice file starts with this line. It tightens the rules about which `id`s a nested component may see, so mistakes become errors instead of silent bugs. It's also why delegates must declare `required property` for their model data. Keep it at the top of new files.

## quickshell's own types

QtQuick gives you shapes and text. quickshell adds what a desktop needs. These are the ones yurice uses most:

| Type                       | What it is                                                             |
| -------------------------- | ---------------------------------------------------------------------- |
| `ShellRoot`                | the top of `shell.qml`, holds everything                               |
| `PanelWindow`              | a window glued to screen edges, on the Wayland layer shell (see below) |
| `Variants`                 | makes one copy of its child per item, usually one per screen           |
| `Singleton`                | base type for singletons                                               |
| `Process`                  | runs a command and gives you its output                                |
| `FileView` + `JsonAdapter` | reads a file, watches it, and maps JSON onto properties                |
| `IpcHandler`               | exposes functions to `qs ipc call` from the command line               |
| `Quickshell.screens`       | the list of monitors                                                   |

### The layer shell

Normal windows are placed by the compositor. A shell's windows aren't normal: a bar must hug the top edge, push other windows down, and stay above them. Wayland's layer shell protocol lets a program ask for exactly that. Every surface goes on one of four layers (`Background`, `Bottom`, `Top`, `Overlay`), can anchor to edges, and can reserve an exclusive zone that tiled windows stay out of.

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

`settings.watchFiles` turns off hot reload while the screen is locked, because saving a file must never reload the shell and drop your lock.

`Component.onCompleted` starts two background jobs. One watches Caps Lock so a toast can tell you when it changes (chapter 18). The other publishes your wallpaper for the login screen (chapter 20).

Each `Variants` makes one copy of its child for every monitor and hands each copy its screen as `modelData`. That gives every screen a wallpaper, a screenshot overlay, a display-confirm dialog and a bar, and it's why `Bar.qml` begins with `required property ShellScreen modelData`. Plug in a monitor and a new bar appears. The picker, lock screen, intro and outro exist once and manage their own screens internally.

Order in this file doesn't decide what's on top. The layer each window asks for does.

Next is the singleton every visible thing depends on: the theme.
