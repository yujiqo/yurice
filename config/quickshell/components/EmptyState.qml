pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Text {
  width: parent.width
  height: Theme.menuItemHeight
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter
  wrapMode: Text.WordWrap
  color: Theme.textVariant
  font.family: Theme.labelFont
  font.pixelSize: Theme.menuTitleSize
}
