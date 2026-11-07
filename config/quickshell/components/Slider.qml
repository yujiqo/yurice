import QtQuick
import qs.theme

Item {
  id: root

  property real value: 0
  property color accent: Theme.primary
  property real step: 0.05
  property bool interactive: true
  property real trackHeight: 14
  readonly property bool pressed: mouse.pressed
  property real dragValue: 0
  property bool glide: false
  readonly property real shown: Math.max(0, Math.min(1, pressed ? dragValue : glide ? spring.value : value))

  onValueChanged: pressed ? spring.jump(value) : spring.target = value

  Spring {
    id: spring
    Component.onCompleted: jump(root.value)
  }

  signal moved(real value)

  readonly property real handleWidth: 4
  readonly property real handleGap: 4
  readonly property real handleX: shown * (width - handleWidth)

  implicitWidth: 200
  implicitHeight: 32

  function emitAt(x) {
    dragValue = Math.max(0, Math.min(1, (x - handleWidth / 2) / (width - handleWidth)));
    moved(dragValue);
  }

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    x: 0
    width: Math.max(0, root.handleX - root.handleGap)
    height: root.trackHeight
    radius: height / 2
    visible: width > 0
    color: root.accent
    topRightRadius: 3
    bottomRightRadius: 3
  }

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    x: root.handleX + root.handleWidth + root.handleGap
    width: Math.max(0, root.width - x)
    height: root.trackHeight
    radius: height / 2
    visible: width > 0
    color: Theme.surfaceContainerHighest
    topLeftRadius: 3
    bottomLeftRadius: 3
  }

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    x: root.handleX
    width: root.handleWidth
    height: root.pressed ? root.height : root.height - 4
    radius: width / 2
    color: root.accent
    Behavior on height {
      NumberAnimation {
        duration: Theme.animPress
      }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: root.interactive
    cursorShape: Qt.PointingHandCursor
    preventStealing: true
    onPressed: event => root.emitAt(event.x)
    onReleased: spring.jump(root.dragValue)
    onPositionChanged: event => root.emitAt(event.x)
    property real wheelAccum: 0
    onWheel: event => {
      wheelAccum += event.angleDelta.y || -event.angleDelta.x;
      const notches = Math.trunc(wheelAccum / 120);
      if (notches === 0)
        return;
      wheelAccum -= notches * 120;
      root.moved(Math.max(0, Math.min(1, root.value + notches * root.step)));
    }
  }
}
