import QtQuick
import qs.theme

Rectangle {
  id: root

  property string icon: ""
  property string text: ""
  property bool selected: false
  property bool available: true
  property bool flat: false

  signal clicked

  implicitWidth: row.implicitWidth + 24
  implicitHeight: 32
  radius: height / 2
  opacity: available ? 1 : 0.45
  color: flat ? "transparent" : selected ? Theme.primary : mouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
  border.width: flat || selected ? 0 : 1
  border.color: Theme.divider
  scale: mouse.pressed ? 0.95 : 1

  Behavior on color {
    ColorAnimation {
      duration: Theme.animHover
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: Theme.animPress
    }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon !== ""
      text: root.icon
      color: root.selected ? Theme.textOnPrimary : Theme.textVariant
      size: Theme.iconSize + 2
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.text !== ""
      text: root.text
      color: root.selected ? Theme.textOnPrimary : Theme.text
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuSubtitleSize
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: root.available
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
