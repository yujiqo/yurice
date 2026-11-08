import QtQuick
import qs.theme

Rectangle {
  property Item target: parent

  anchors.fill: parent
  z: 100
  opacity: target.activeFocus ? 1 : 0
  visible: opacity > 0
  color: "transparent"
  radius: parent.radius ?? height / 2
  border.width: 2
  border.color: Theme.text

  Behavior on opacity {
    NumberAnimation {
      duration: Theme.animHover
    }
  }
}
