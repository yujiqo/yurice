import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.theme
import qs.components
import qs.services

PanelWindow {
  id: root

  property string phase: "closed"
  property ShellScreen targetScreen: Quickshell.screens[0] ?? null
  property list<string> items: []
  property int originIndex: 0
  property int anchorIndex: 0
  property int selected: 0
  property real zoom: 1
  property real focusX: 0
  property real focusY: 0

  readonly property bool interactive: phase === "opening" || phase === "open"
  readonly property real tileW: targetScreen?.width ?? 1920
  readonly property real tileH: targetScreen?.height ?? 1080
  readonly property real dpr: targetScreen?.devicePixelRatio ?? 1
  readonly property real gap: Theme.pickerGap / Theme.pickerScale
  readonly property int cols: Math.max(1, Math.ceil(Math.sqrt(items.length)))
  readonly property real cornerRadius: Theme.pickerRadius * (1 - zoom) / (1 - Theme.pickerScale) / zoom

  screen: targetScreen
  visible: phase !== "closed"
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "yurice-wallpaper-picker"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  color: "transparent"

  function col(i) {
    return i % cols;
  }

  function row(i) {
    return Math.floor(i / cols);
  }

  function focusOn(i) {
    focusX = col(i) * (tileW + gap) + tileW / 2;
    focusY = row(i) * (tileH + gap) + tileH / 2;
  }

  function open() {
    const list = Wallpapers.wallpapers;
    if (phase !== "closed" || list.length === 0) {
      if (phase === "closed")
        Wallpapers.pickerOpen = false;
      return;
    }
    targetScreen = Quickshell.screens.find(s => s.name === Niri.focusedOutput) ?? Quickshell.screens[0];
    originIndex = Math.max(0, list.indexOf(Wallpapers.current));
    anchorIndex = originIndex;
    selected = originIndex;
    items = list;
    zoom = 1;
    content.opacity = 0;
    focusOn(originIndex);
    phase = "opening";
    content.forceActiveFocus();
    openAnim.start();
  }

  function reveal(show) {
    for (let i = 0; i < tiles.count; i++) {
      const tile = tiles.itemAt(i);
      if (!tile)
        continue;
      if (i === anchorIndex) {
        tile.fadeTo(1, 0);
        continue;
      }
      const dist = Math.abs(col(i) - col(anchorIndex)) + Math.abs(row(i) - row(anchorIndex));
      tile.fadeTo(show ? 1 : 0, show ? dist * Theme.animPickerStagger : 0);
    }
  }

  function select(i) {
    if (i < 0 || i >= items.length)
      return;
    selected = i;
    focusOn(i);
  }

  function move(dx, dy) {
    const c = col(selected) + dx;
    const r = row(selected) + dy;
    if (c < 0 || c >= cols || r < 0)
      return;
    select(r * cols + c);
  }

  function confirm() {
    if (interactive)
      close(selected);
  }

  function cancel() {
    if (!interactive)
      return;
    select(originIndex);
    close(originIndex);
  }

  function close(index) {
    openAnim.stop();
    phase = "closing";
    Wallpapers.pickerOpen = false;
    anchorIndex = index;
    if (index !== originIndex)
      Wallpapers.set(items[index]);
    reveal(false);
    closeAnim.start();
  }

  function finishClose() {
    phase = "closed";
    items = [];
    zoom = 1;
    Wallpapers.pickerOpen = false;
  }

  function handleKey(event) {
    if (!interactive)
      return;
    switch (event.key) {
    case Qt.Key_Escape:
      cancel();
      break;
    case Qt.Key_Return:
    case Qt.Key_Enter:
      confirm();
      break;
    case Qt.Key_Left:
    case Qt.Key_H:
      move(-1, 0);
      break;
    case Qt.Key_Right:
    case Qt.Key_L:
      move(1, 0);
      break;
    case Qt.Key_Up:
    case Qt.Key_K:
      move(0, -1);
      break;
    case Qt.Key_Down:
    case Qt.Key_J:
      move(0, 1);
      break;
    default:
      return;
    }
    event.accepted = true;
  }

  Behavior on focusX {
    enabled: root.phase !== "closed"
    NumberAnimation {
      duration: Theme.animMove
      easing.type: Theme.easeOut
    }
  }

  Behavior on focusY {
    enabled: root.phase !== "closed"
    NumberAnimation {
      duration: Theme.animMove
      easing.type: Theme.easeOut
    }
  }

  Connections {
    target: Wallpapers

    function onPickerOpenChanged() {
      if (Wallpapers.pickerOpen)
        root.open();
      else
        root.cancel();
    }
  }

  SequentialAnimation {
    id: openAnim

    NumberAnimation {
      target: content
      property: "opacity"
      to: 1
      duration: Theme.animPickerFade
      easing.type: Theme.easeOut
    }
    ScriptAction {
      script: root.reveal(true)
    }
    NumberAnimation {
      target: root
      property: "zoom"
      to: Theme.pickerScale
      duration: Theme.animPickerZoom
      easing.type: Easing.InOutCubic
    }
    ScriptAction {
      script: root.phase = "open"
    }
  }

  SequentialAnimation {
    id: closeAnim

    NumberAnimation {
      target: root
      property: "zoom"
      to: 1
      duration: Theme.animPickerZoom
      easing.type: Easing.InOutCubic
    }
    NumberAnimation {
      target: content
      property: "opacity"
      to: 0
      duration: Theme.animPickerFade
      easing.type: Theme.easeOut
    }
    ScriptAction {
      script: root.finishClose()
    }
  }

  Item {
    id: content

    anchors.fill: parent
    opacity: 0
    focus: true
    Keys.onPressed: event => root.handleKey(event)

    Rectangle {
      anchors.fill: parent
      color: Theme.surface
    }

    Item {
      id: grid

      transformOrigin: Item.TopLeft
      scale: root.zoom
      x: content.width / 2 - root.focusX * root.zoom
      y: content.height / 2 - root.focusY * root.zoom

      Repeater {
        id: tiles

        model: root.items

        delegate: ClippingRectangle {
          id: tile

          required property string modelData
          required property int index

          readonly property bool isSelected: index === root.selected
          readonly property bool needsFull: isSelected || index === root.anchorIndex

          x: root.col(index) * (root.tileW + root.gap)
          y: root.row(index) * (root.tileH + root.gap)
          width: root.tileW
          height: root.tileH
          radius: root.cornerRadius
          color: Theme.surface
          opacity: 0

          Component.onCompleted: opacity = index === root.anchorIndex ? 1 : 0

          function fadeTo(value, delay) {
            fadeAnim.stop();
            fadeDelay.duration = delay;
            fadeOpacity.to = value;
            fadeAnim.start();
          }

          SequentialAnimation {
            id: fadeAnim

            PauseAnimation {
              id: fadeDelay
            }
            NumberAnimation {
              id: fadeOpacity
              target: tile
              property: "opacity"
              duration: Theme.animPickerReveal
              easing.type: Theme.easeOut
            }
          }

          Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: Utility.fileUrl(tile.modelData)
            sourceSize: Qt.size(root.tileW * root.dpr * Theme.pickerScale * 1.5, root.tileH * root.dpr * Theme.pickerScale * 1.5)
          }

          Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: tile.needsFull ? Utility.fileUrl(tile.modelData) : ""
            sourceSize: Qt.size(root.tileW * root.dpr, root.tileH * root.dpr)
            visible: status === Image.Ready
          }

          Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: tile.radius
            border.width: Theme.pickerBorder / root.zoom
            border.color: Theme.text
            opacity: tile.isSelected && root.phase === "open" ? 1 : 0

            Behavior on opacity {
              NumberAnimation {
                duration: Theme.animHover
                easing.type: Theme.easeOut
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            enabled: root.interactive
            onClicked: root.select(tile.index)
            onDoubleClicked: {
              root.select(tile.index);
              root.confirm();
            }
          }
        }
      }
    }
  }
}
