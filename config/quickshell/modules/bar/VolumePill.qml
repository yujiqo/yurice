import QtQuick
import qs.theme
import qs.components
import qs.services

Pill {
  segments: {
    const percent = Audio.percent;
    if (Audio.wiredHeadphones)
      return [Audio.muted ? Utility.seg("headset_off", "Muted", Theme.off) : Utility.seg("headphones", percent + "%", Theme.volume)];
    if (Audio.muted || percent === 0)
      return [Utility.seg("volume_off", Audio.muted ? "Muted" : "0%", Theme.off)];
    const icon = Utility.pick(percent, [[66, "volume_up"], [33, "volume_down"]], "volume_mute");
    return [Utility.seg(icon, percent + "%", Theme.volume)];
  }
  clickable: true
  onClicked: Audio.toggleMute()

  WheelHandler {
    onWheel: event => Audio.changeVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
  }
}
