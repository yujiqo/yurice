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

  readonly property real progress: progressSpring.value
  readonly property real zoom: 1 + (Theme.pickerScale - 1) * progress
  readonly property bool interactive: phase === "opening" || phase === "open"
  readonly property real tileW: targetScreen?.width ?? 1920
  readonly property real tileH: targetScreen?.height ?? 1080
  readonly property real dpr: targetScreen?.devicePixelRatio ?? 1
  readonly property real gap: Theme.pickerGap / Theme.pickerScale
  readonly property int cols: Math.max(1, Math.ceil(Math.sqrt(items.length)))
  readonly property real cornerRadius: Theme.pickerRadius * (1 - zoom) / (1 - Theme.pickerScale) / zoom
  readonly property size thumbSize: {
    let w = 0;
    let h = 0;
    for (const s of Quickshell.screens) {
      w = Math.max(w, s.width * s.devicePixelRatio);
      h = Math.max(h, s.height * s.devicePixelRatio);
    }
    return Qt.size(w * Theme.pickerScale * 1.5, h * Theme.pickerScale * 1.5);
  }

  screen: targetScreen
  visible: phase !== "closed" && phase !== "loading"
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

  function focusOn(i, animate) {
    const x = col(i) * (tileW + gap) + tileW / 2;
    const y = row(i) * (tileH + gap) + tileH / 2;
    if (animate) {
      focusXSpring.target = x;
      focusYSpring.target = y;
    } else {
      focusXSpring.jump(x);
      focusYSpring.jump(y);
    }
  }

  function syncItems() {
    if (items.join("\n") !== Wallpapers.wallpapers.join("\n"))
      items = Wallpapers.wallpapers;
  }

  function open() {
    if (phase !== "closed")
      return;
    syncItems();
    if (items.length === 0) {
      Wallpapers.pickerOpen = false;
      return;
    }
    targetScreen = Quickshell.screens.find(s => s.name === Niri.focusedOutput) ?? Quickshell.screens[0];
    originIndex = Math.max(0, items.indexOf(Wallpapers.current));
    anchorIndex = originIndex;
    selected = originIndex;
    progressSpring.jump(0);
    content.opacity = 0;
    focusOn(originIndex, false);
    phase = "loading";
    loadTimeout.restart();
    tryStart(false);
  }

  function allReady() {
    for (let i = 0; i < tiles.count; i++) {
      const tile = tiles.itemAt(i);
      if (!tile || !tile.ready)
        return false;
    }
    return true;
  }

  function tryStart(force) {
    if (phase !== "loading" || (!force && !allReady()))
      return;
    loadTimeout.stop();
    phase = "opening";
    content.forceActiveFocus();
    fadeIn.start();
    progressSpring.target = 1;
  }

  function select(i) {
    if (i < 0 || i >= items.length)
      return;
    selected = i;
    focusOn(i, true);
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
    if (phase === "loading") {
      loadTimeout.stop();
      phase = "closed";
      Wallpapers.pickerOpen = false;
      return;
    }
    if (!interactive)
      return;
    select(originIndex);
    close(originIndex);
  }

  function close(index) {
    phase = "closing";
    Wallpapers.pickerOpen = false;
    anchorIndex = index;
    if (index !== originIndex)
      Wallpapers.set(items[index]);
    progressSpring.target = 0;
  }

  function maybeFadeOut() {
    if (phase !== "closing" || fadeOut.running || progress > Theme.pickerFadeOutAt)
      return;
    fadeIn.stop();
    fadeOut.start();
  }

  function finishClose() {
    phase = "closed";
    progressSpring.jump(0);
    syncItems();
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

  Component.onCompleted: syncItems()

  Spring {
    id: progressSpring
    onValueChanged: root.maybeFadeOut()
    onSettled: {
      if (root.phase === "opening" && target === 1)
        root.phase = "open";
      root.maybeFadeOut();
    }
  }

  Spring {
    id: focusXSpring
    epsilon: 0.01
  }

  Spring {
    id: focusYSpring
    epsilon: 0.01
  }

  Timer {
    id: loadTimeout
    interval: 1000
    onTriggered: root.tryStart(true)
  }

  NumberAnimation {
    id: fadeIn
    target: content
    property: "opacity"
    to: 1
    duration: Theme.animPickerFade
    easing.type: Theme.easeOut
  }

  NumberAnimation {
    id: fadeOut
    target: content
    property: "opacity"
    to: 0
    duration: Theme.animPickerFade
    easing.type: Theme.easeOut
    onFinished: root.finishClose()
  }

  Connections {
    target: Wallpapers

    function onWallpapersChanged() {
      if (root.phase === "closed")
        root.syncItems();
    }

    function onPickerOpenChanged() {
      if (Wallpapers.pickerOpen)
        root.open();
      else
        root.cancel();
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
      x: content.width / 2 - focusXSpring.value * root.zoom
      y: content.height / 2 - focusYSpring.value * root.zoom

      Repeater {
        id: tiles

        model: root.items

        delegate: ClippingRectangle {
          id: tile

          required property string modelData
          required property int index

          readonly property bool isSelected: index === root.selected
          readonly property bool isAnchor: index === root.anchorIndex
          readonly property bool needsFull: root.phase !== "closed" && (isSelected || isAnchor)
          readonly property bool ready: done(thumb) && (!isAnchor || done(full))
          readonly property int distance: Math.abs(root.col(index) - root.col(root.anchorIndex)) + Math.abs(root.row(index) - root.row(root.anchorIndex))
          readonly property real revealAt: Math.min(distance * Theme.pickerStagger, 1 - Theme.pickerRevealWidth)

          x: root.col(index) * (root.tileW + root.gap)
          y: root.row(index) * (root.tileH + root.gap)
          width: root.tileW
          height: root.tileH
          radius: root.cornerRadius
          color: Theme.surface
          opacity: isAnchor ? 1 : Math.max(0, Math.min(1, (root.progress - revealAt) / Theme.pickerRevealWidth))

          onReadyChanged: Qt.callLater(root.tryStart, false)

          function done(img) {
            return img.status === Image.Ready || img.status === Image.Error;
          }

          Image {
            id: thumb
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            mipmap: true
            source: Utility.fileUrl(tile.modelData)
            sourceSize: root.thumbSize
          }

          Image {
            id: full
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
            opacity: tile.isSelected && root.interactive && root.progress > 0.9 ? 1 : 0

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
