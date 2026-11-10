pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

InfoRow {
  id: root

  property string valueText: ""
  property real valueWidth: 64
  property bool canDecrease: true
  property bool canIncrease: true

  signal decreased
  signal increased

  width: parent.width
  value: ""

  Row {
    anchors.right: parent.right
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    IconButton {
      anchors.verticalCenter: parent.verticalCenter
      icon: "remove"
      opacity: root.canDecrease ? 1 : 0.4
      onClicked: root.decreased()
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: root.valueWidth
      horizontalAlignment: Text.AlignHCenter
      text: root.valueText
      opacity: root.valueOpacity
      color: Theme.text
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuSubtitleSize + 1

      Behavior on width {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }
    }

    IconButton {
      anchors.verticalCenter: parent.verticalCenter
      icon: "add"
      opacity: root.canIncrease ? 1 : 0.4
      onClicked: root.increased()
    }
  }
}
