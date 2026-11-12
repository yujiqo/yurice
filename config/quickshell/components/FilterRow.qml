import QtQuick
import qs.theme

Row {
  id: root

  property string title
  spacing: 6

  Text {
    anchors.verticalCenter: parent.verticalCenter
    width: 60
    leftPadding: 10
    text: root.title
    color: Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuSubtitleSize
  }
}
