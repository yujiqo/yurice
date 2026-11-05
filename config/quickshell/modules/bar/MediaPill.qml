import QtQuick
import Quickshell.Services.Mpris
import qs.theme
import qs.components

Pill {
  id: root

  readonly property var player: Mpris.players.values.find(player => player.isPlaying) ?? Mpris.players.values[0] ?? null

  icon: "music_note"
  iconColor: Theme.music
  maxLabelWidth: 300
  label: player ? `${player.trackArtist || "Unknown"} — ${player.trackTitle || ""}` : "Nothing is playing"
}
