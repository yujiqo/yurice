import QtQuick
import qs.theme

Rectangle {
  id: root

  property string icon: ""
  property color iconColor: Theme.primary
  property color accent: Theme.primary
  readonly property color activeContent: Theme.textOnPrimary
  property string title: ""
  property string subtitle: ""
  property bool active: false
  property Component leading: null
  default property alias trailing: trailingRow.data

  signal clicked

  activeFocusOnTab: true
  implicitHeight: Theme.menuItemHeight
  radius: Theme.menuItemRadius
  color: active ? accent : mouse.containsMouse ? Theme.surfaceContainerHigh : Qt.alpha(Theme.surfaceContainerHigh, 0)

  Behavior on color {
    ColorAnimation {
      duration: Theme.animHover
    }
  }

  FocusRing {}

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  Item {
    id: lead
    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    width: root.leading ? leadLoader.width : iconText.implicitWidth
    height: root.leading ? leadLoader.height : iconText.implicitHeight

    Icon {
      id: iconText
      visible: !root.leading
      text: root.icon
      color: root.active ? root.activeContent : root.iconColor
      size: Theme.menuIconSize
    }

    Loader {
      id: leadLoader
      sourceComponent: root.leading
    }
  }

  Column {
    anchors.left: lead.right
    anchors.leftMargin: 12
    anchors.right: trailingRow.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter

    Label {
      width: parent.width
      text: root.title
      color: root.active ? root.activeContent : Theme.text
      pixelSize: Theme.menuTitleSize
    }

    Label {
      width: parent.width
      text: root.subtitle
      visible: text !== ""
      color: root.active ? root.activeContent : Theme.textVariant
      opacity: root.active ? 0.8 : 1
      pixelSize: Theme.menuSubtitleSize
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
