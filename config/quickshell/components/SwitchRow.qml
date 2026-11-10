pragma ComponentBehavior: Bound
import QtQuick

InfoRow {
  id: root

  property bool checked: false
  property bool dimmed: false

  signal toggled

  width: parent.width
  value: ""

  Switch {
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    checked: root.checked
    opacity: root.dimmed ? 0.4 : 1
    onToggled: root.toggled()
  }
}
