import QtQuick
import Quickshell.Services.Pipewire
import qs.theme
import qs.components

Pill {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool muted: sink?.audio?.muted ?? false
  readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)

  readonly property bool wiredHeadphones: {
    const props = sink?.properties ?? {};
    if (String(props["device.api"] ?? "") !== "alsa")
      return false;
    const icon = String(props["device.icon_name"] ?? props["device.icon-name"] ?? "").toLowerCase();
    const name = String(props["node.nick"] ?? sink?.nickname ?? sink?.name ?? "").toLowerCase();
    return icon === "audio-headphones" || name.includes("headphone");
  }

  readonly property var segment: {
    if (wiredHeadphones)
      return muted ? Utility.seg("headset_off", "Muted", Theme.off) : Utility.seg("headphones", percent + "%", Theme.volume);
    if (muted || percent === 0)
      return Utility.seg("volume_off", muted ? "Muted" : "0%", Theme.off);
    const icon = Utility.pick(percent, [[66, "volume_up"], [33, "volume_down"]], "volume_mute");
    return Utility.seg(icon, percent + "%", Theme.volume);
  }

  segments: [segment]
  clickable: true
  onClicked: if (root.sink?.audio)
    root.sink.audio.muted = !root.sink.audio.muted

  PwObjectTracker {
    objects: [root.sink]
  }

  WheelHandler {
    onWheel: event => {
      if (!root.sink?.audio)
        return;
      const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
      root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step));
    }
  }
}
