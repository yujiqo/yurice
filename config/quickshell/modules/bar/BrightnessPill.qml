import QtQuick
import qs.theme
import qs.components
import qs.services

Pill {
  visible: Brightness.available
  segments: [Utility.seg(Utility.pick(Brightness.percent, [[66, "brightness_high"], [33, "brightness_medium"]], "brightness_low"), Brightness.percent + "%", Theme.brightness)]

  WheelHandler {
    onWheel: event => Brightness.step(event.angleDelta.y > 0)
  }
}
