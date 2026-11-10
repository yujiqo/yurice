import QtQuick
import qs.theme

Icon {
  id: root

  property color tint: Theme.primary

  text: "progress_activity"
  color: tint
  size: Theme.menuIconSize
  width: 32
  height: 32
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter

  NumberAnimation on rotation {
    running: root.visible
    from: 0
    to: 360
    duration: 900
    loops: Animation.Infinite
  }
}
