pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Item {
  id: root

  property bool shown: false
  property real leading: Theme.pillIconGap
  default property alias content: holder.data

  implicitWidth: (holder.childrenRect.width + leading) * progress.value
  implicitHeight: Theme.pillHeight
  clip: true
  visible: progress.value > 0.001

  Spring {
    id: progress
    target: root.shown ? 1 : 0
    Component.onCompleted: value = target
  }

  Item {
    id: holder
    x: root.leading
    anchors.verticalCenter: parent.verticalCenter
    width: childrenRect.width
    height: childrenRect.height
    opacity: Math.max(0, Math.min(1, progress.value))
  }
}
