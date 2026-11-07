import QtQuick
import qs.theme

Item {
  id: root

  property bool shown: false
  readonly property real progress: Math.max(0, Math.min(1, spring.value))

  implicitWidth: Theme.pillSegmentGap * (1 + progress) + progress
  implicitHeight: Theme.pillHeight

  Spring {
    id: spring
    target: root.shown ? 1 : 0
    Component.onCompleted: value = target
  }

  Rectangle {
    anchors.centerIn: parent
    width: 1
    height: 14 * root.progress
    radius: 0.5
    color: Theme.divider
    opacity: root.progress
  }
}
