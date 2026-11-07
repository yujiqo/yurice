import QtQuick
import qs.theme

Text {
  id: root

  property color tint: Theme.primary

  text: "progress_activity"
  color: tint
  font.family: Theme.iconFont
  font.pixelSize: Theme.menuIconSize

  RotationAnimator on rotation {
    running: root.visible
    from: 0
    to: 360
    duration: 900
    loops: Animation.Infinite
  }
}
