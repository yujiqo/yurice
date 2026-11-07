import QtQuick
import qs.theme

Rectangle {
  id: root

  default property alias content: row.data
  readonly property bool hovered: hover.hovered
  property real padding: Theme.pillPadding
  property real spacing: Theme.pillSegmentGap
  property bool clickable: false

  signal clicked(var mouse)

  implicitWidth: row.implicitWidth + padding * 2
  implicitHeight: Theme.pillHeight
  radius: Theme.pillHeight / 2
  color: Theme.surface
  clip: true
  scale: mouse.pressed ? 0.95 : 1

  Behavior on scale {
    NumberAnimation {
      duration: Theme.animPress
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: root.clickable
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: event => root.clicked(event)
  }

  Row {
    id: row
    x: root.padding
    height: Theme.pillHeight
    spacing: root.spacing
  }

  HoverHandler {
    id: hover
  }
}
