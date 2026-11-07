import QtQuick
import qs.theme

Item {
  id: root

  property bool shown: false
  property real leading: 0
  default property alias content: holder.data
  readonly property real progress: Math.max(0, Math.min(1, spring.value))

  implicitHeight: (holder.childrenRect.height + leading) * spring.value
  clip: true
  visible: spring.value > 0.001

  Spring {
    id: spring
    target: root.shown ? 1 : 0
    Component.onCompleted: value = target
  }

  Item {
    id: holder
    width: parent.width
    height: childrenRect.height
    y: root.leading + (root.progress - 1) * 12
    opacity: root.progress
  }
}
