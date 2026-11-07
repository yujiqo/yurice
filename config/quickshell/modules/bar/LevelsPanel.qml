import QtQuick
import qs.theme
import qs.components
import qs.services

Item {
  id: root

  required property string kind
  readonly property bool isVolume: kind === "volume"
  readonly property color accent: isVolume ? (Audio.muted ? Theme.off : Theme.volume) : Theme.brightness
  readonly property real value: isVolume ? Audio.volume : Brightness.percent / 100

  implicitHeight: 44

  IconButton {
    id: button
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    icon: root.isVolume ? (Audio.muted ? "volume_off" : "volume_up") : "brightness_6"
    iconColor: root.accent
    onClicked: {
      if (root.isVolume)
        Audio.toggleMute();
    }
  }

  Slider {
    anchors.left: button.right
    anchors.leftMargin: 8
    anchors.right: label.left
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    accent: root.accent
    value: root.value
    onMoved: v => root.isVolume ? Audio.setVolume(v) : Brightness.set(v)
  }

  Text {
    id: label
    anchors.right: parent.right
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    width: 44
    horizontalAlignment: Text.AlignRight
    text: Math.round(root.value * 100) + "%"
    color: Theme.text
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuTitleSize
  }
}
