pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Rectangle {
  id: root

  property real padding: 4
  property real spacing: 0
  default property alias content: column.data

  width: parent.width
  implicitHeight: column.implicitHeight + padding * 2
  height: implicitHeight
  radius: Theme.menuItemRadius
  color: Theme.surfaceContainer

  Column {
    id: column
    y: root.padding
    width: parent.width
    spacing: root.spacing
  }
}
