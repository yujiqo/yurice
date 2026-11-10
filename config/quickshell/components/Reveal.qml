pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Item {
  id: root

  property bool shown: false
  property real leading: Theme.pillIconGap
  default property alias content: holder.data

  implicitWidth: (holder.childrenRect.width + leading) * spring.value
  implicitHeight: Theme.pillHeight
  clip: true
  visible: spring.value > 0.001

  Spring {
    id: spring
    target: root.shown ? 1 : 0
    Component.onCompleted: snap()
  }

  Item {
    id: holder
    x: root.leading
    anchors.verticalCenter: parent.verticalCenter
    width: childrenRect.width
    height: childrenRect.height
    opacity: spring.progress
  }
}
