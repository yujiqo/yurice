pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Item {
  id: root

  property string icon: ""
  property color iconColor: Theme.primary
  property string title: ""
  property string subtitle: ""
  property bool smoothTitle: false
  default property alias trailing: trailingRow.data

  width: parent.width
  height: 64

  Icon {
    id: icon
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    text: root.icon
    color: root.iconColor
    size: 44
  }

  Column {
    anchors.left: icon.right
    anchors.leftMargin: 14
    anchors.right: trailingRow.left
    anchors.rightMargin: trailingRow.width > 0 ? 10 : 0
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Label {
      text: root.title
      smooth: root.smoothTitle
      pixelSize: 30
    }

    Label {
      width: parent.width
      text: root.subtitle
      color: Theme.textVariant
      pixelSize: Theme.menuSubtitleSize
    }
  }

  Row {
    id: trailingRow
    anchors.right: parent.right
    anchors.rightMargin: width > 0 ? 10 : 0
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6
  }
}
