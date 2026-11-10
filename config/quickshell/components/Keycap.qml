pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Rectangle {
  id: root

  property alias text: label.text

  implicitWidth: Math.max(implicitHeight, label.implicitWidth + 12)
  implicitHeight: 24
  radius: 7
  color: Theme.surfaceContainerHighest

  Text {
    id: label
    anchors.centerIn: parent
    color: Theme.text
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuSubtitleSize - 1
  }
}
