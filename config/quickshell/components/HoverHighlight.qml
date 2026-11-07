import QtQuick
import qs.theme

Rectangle {
  property bool active: false

  height: Theme.pillHeight - 6
  radius: height / 2
  color: Theme.surfaceContainerHigh
  opacity: active ? 1 : 0
  scale: active ? 1 : 0.9

  Behavior on opacity {
    NumberAnimation {
      duration: Theme.animHover
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: Theme.animMove
      easing.type: Easing.OutBack
    }
  }
}
