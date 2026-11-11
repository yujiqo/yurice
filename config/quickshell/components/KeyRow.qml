pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Item {
  id: root

  property string label: ""
  property var keys: []

  implicitHeight: 32

  Text {
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.right: keycaps.left
    anchors.rightMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    elide: Text.ElideRight
    color: Theme.text
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuSubtitleSize
  }

  Row {
    id: keycaps
    anchors.right: parent.right
    anchors.rightMargin: 4
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    Repeater {
      model: root.keys

      Keycap {
        required property string modelData
        text: modelData
      }
    }
  }
}
