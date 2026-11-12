pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Item {
  id: root

  property Flickable flickable: null
  property real inset: 4
  property real thickness: 3
  property Item host: null
  property Item bar: null
  property real originX: 0
  property real originY: 0
  property real chainOpacity: 1
  readonly property bool inGutter: host !== null && host !== flickable
  readonly property real viewHeight: flickable?.height ?? 0
  readonly property real contentHeight: flickable?.contentHeight ?? 0
  readonly property real track: viewHeight - inset * 2
  readonly property real range: contentHeight - viewHeight
  readonly property bool scrollable: flickable !== null && flickable.visible && range > 1
  readonly property real position: scrollable ? Math.max(0, Math.min(1, (flickable.contentY - flickable.originY) / range)) : 0
  readonly property real barHeight: Math.max(20, track * viewHeight / Math.max(1, contentHeight))
  property real strength: scrollable ? (flickable.moving ? 0.7 : 0.3) : 0

  visible: false

  function findHost() {
    for (let item = flickable?.parent; item; item = item.parent) {
      if (item.objectName === "panelArea")
        return item;
    }
    return flickable;
  }

  function update() {
    if (!flickable)
      return;
    if (!bar) {
      host = findHost();
      bar = barComponent.createObject(host);
    }
    if (!inGutter) {
      originX = flickable.width - thickness - 2;
      originY = 0;
      chainOpacity = 1;
      return;
    }
    const point = flickable.mapToItem(host, flickable.width, 0);
    originX = point.x + (Theme.panelPadding - thickness) / 2;
    originY = point.y;
    let opacity = 1;
    for (let item = flickable; item && item !== host; item = item.parent)
      opacity *= item.opacity;
    chainOpacity = opacity;
  }

  Component.onDestruction: bar?.destroy()

  Behavior on strength {
    NumberAnimation {
      duration: Theme.animHover
    }
  }

  FrameAnimation {
    running: root.scrollable
    onTriggered: root.update()
  }

  Component {
    id: barComponent

    Rectangle {
      z: 10
      x: root.originX
      y: root.originY + root.inset + (root.track - height) * root.position
      width: root.thickness
      height: root.barHeight
      radius: width / 2
      color: Theme.textVariant
      opacity: root.strength * root.chainOpacity
      visible: opacity > 0.01
    }
  }
}
