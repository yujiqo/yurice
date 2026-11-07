import QtQuick
import qs.theme

Icon {
  id: root

  property color tint: Theme.primary

  text: "progress_activity"
  color: tint
  size: Theme.menuIconSize

  RotationAnimator on rotation {
    running: root.visible
    from: 0
    to: 360
    duration: 900
    loops: Animation.Infinite
  }
}
