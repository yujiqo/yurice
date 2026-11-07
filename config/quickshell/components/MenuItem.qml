import QtQuick
import qs.theme

Rectangle {
  id: root

  property string icon: ""
  property color iconColor: Theme.primary
  property color accent: Theme.primary
  readonly property color onActive: Theme.onPrimary
  property string title: ""
  property string subtitle: ""
  property bool active: false
  default property alias trailing: trailingRow.data

  signal clicked

  implicitHeight: Theme.menuItemHeight
  radius: Theme.menuItemRadius
  color: active ? accent : mouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"

  Behavior on color {
    ColorAnimation {
      duration: Theme.animHover
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  Icon {
    id: iconText
    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    text: root.icon
    color: root.active ? root.onActive : root.iconColor
    size: Theme.menuIconSize
  }

  Column {
    anchors.left: iconText.right
    anchors.leftMargin: 12
    anchors.right: trailingRow.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter

    Text {
      width: parent.width
      text: root.title
      elide: Text.ElideRight
      color: root.active ? root.onActive : Theme.text
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuTitleSize
    }

    Text {
      width: parent.width
      text: root.subtitle
      visible: text !== ""
      elide: Text.ElideRight
      color: root.active ? root.onActive : Theme.textVariant
      opacity: root.active ? 0.8 : 1
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuSubtitleSize
    }
  }

  Row {
    id: trailingRow
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4
  }
}
