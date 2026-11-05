pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: !!sink?.audio
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

  function toggleMute() {
    if (ready)
      sink.audio.muted = !sink.audio.muted;
  }

  function changeVolume(delta) {
    if (ready)
      sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta));
  }

  PwObjectTracker {
    objects: [root.sink]
  }
}
