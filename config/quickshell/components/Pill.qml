import QtQuick
import qs.theme

Rectangle {
  id: root
  property alias text: label.text
  property color fg: Theme.text

  implicitWidth: label.implicitWidth + Theme.s3 * 2
  implicitHeight: Theme.s4
  radius: Theme.rNormal
  color: Theme.surface

  Text {
    id: label
    anchors.centerIn: parent
    color: root.fg
    font.pixelSize: Theme.fsNormal
  }
}
