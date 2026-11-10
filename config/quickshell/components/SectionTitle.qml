pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Text {
  property string title: ""

  leftPadding: 8
  bottomPadding: 4
  text: title.toUpperCase()
  color: Theme.clock
  font.family: Theme.labelFont
  font.pixelSize: Theme.menuSubtitleSize - 2
  font.letterSpacing: 1
  font.bold: true
}
