import QtQuick
import qs.theme

Item {
  id: root

  property string icon: ""
  property string label: ""
  property string value: ""
  property color valueColor: Theme.text
  property real valueOpacity: 1

  implicitHeight: 38

  Icon {
    id: iconText
    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    width: 24
    horizontalAlignment: Text.AlignHCenter
    text: root.icon
    color: Theme.primary
    size: Theme.menuIconSize - 2
  }

  Label {
    anchors.left: iconText.right
    anchors.leftMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    color: Theme.textVariant
    pixelSize: Theme.menuSubtitleSize
  }

  Label {
    anchors.right: parent.right
    anchors.rightMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    maxWidth: root.width * 0.6
    text: root.value
    color: root.valueColor
    opacity: root.valueOpacity
    pixelSize: Theme.menuSubtitleSize + 1
  }
}
