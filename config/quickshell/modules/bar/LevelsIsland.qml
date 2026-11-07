import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  readonly property var volumeSegment: {
    const percent = Audio.percent;
    if (Audio.wiredHeadphones)
      return Audio.muted ? Utility.seg("headset_off", "Muted", Theme.off) : Utility.seg("headphones", percent + "%", Theme.volume);
    if (Audio.muted || percent === 0)
      return Utility.seg("volume_off", Audio.muted ? "Muted" : "0%", Theme.off);
    return Utility.seg(Utility.pick(percent, [[66, "volume_up"], [33, "volume_down"]], "volume_mute"), percent + "%", Theme.volume);
  }

  Segment {
    visible: Brightness.available
    icon: Utility.pick(Brightness.percent, [[66, "brightness_high"], [33, "brightness_medium"]], "brightness_low")
    label: Brightness.percent + "%"
    color: Theme.brightness
    showLabel: root.hovered
    onWheel: event => Brightness.step(event.angleDelta.y > 0)
  }

  Segment {
    icon: root.volumeSegment.icon
    label: root.volumeSegment.label
    color: root.volumeSegment.color
    showLabel: root.hovered
    clickable: true
    onClicked: Audio.toggleMute()
    onWheel: event => Audio.changeVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
  }
}
