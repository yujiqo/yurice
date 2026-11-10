import QtQuick
import qs.theme

Rectangle {
  id: root

  property string icon: ""
  property color iconColor: Theme.textVariant
  signal clicked

  activeFocusOnTab: true
  implicitWidth: 32
  implicitHeight: 32
  radius: width / 2
  color: mouse.containsMouse ? Theme.surfaceContainerHighest : Qt.alpha(Theme.surfaceContainerHighest, 0)

  Behavior on color {
    ColorAnimation {
      duration: Theme.animHover
    }
  }

  Icon {
    anchors.centerIn: parent
    text: root.icon
    color: root.iconColor
    size: Theme.menuIconSize
  }

  FocusRing {}

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
