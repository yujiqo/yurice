// VolumeWidget.qml — thin binding of SliderRow to Pipewire.defaultAudioSink. PwObjectTracker
// is required: PwNodeAudio's properties (volume, muted) read as invalid until the node is
// bound through it (verified in the installed Pipewire qmltypes, not assumed).
import Quickshell.Services.Pipewire
import qs.components

SliderRow {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: sink !== null && sink.audio !== null
  readonly property bool muted: ready && sink.audio.muted

  visible: ready
  icon: muted ? "🔇" : "🔊"
  value: (ready && !muted) ? sink.audio.volume : 0
  onMoved: v => { if (ready) sink.audio.volume = v }
  onIconClicked: { if (ready) sink.audio.muted = !sink.audio.muted }

  PwObjectTracker { objects: root.sink ? [root.sink] : [] }
}
