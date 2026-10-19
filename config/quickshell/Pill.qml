import QtQuick

Rectangle {
  id: root
  property alias text: label.text
  property color fg: "#cdd6f4"

  implicitWidth: label.implicitWidth + 16
  implicitHeight: 22
  radius: 11
  color: "#313244"

  Text {
    id: label
    anchors.centerIn: parent
    color: root.fg
    font.pixelSize: 15
  }
}
