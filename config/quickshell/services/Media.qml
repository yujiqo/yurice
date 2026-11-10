pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import qs.components

Singleton {
  id: root

  readonly property var liveNames: poller.value.split("\n").filter(n => n !== "")
  readonly property var players: Mpris.players.values.filter(p => liveNames.some(n => n === p.dbusName || n === "org.mpris.MediaPlayer2." + p.dbusName))
  readonly property var playing: players.find(p => p.isPlaying) ?? null
  property string selected: ""
  readonly property var active: players.find(p => p.dbusName === selected) ?? playing ?? null

  onPlayingChanged: {
    if (playing)
      selected = playing.dbusName;
  }

  function select(player) {
    selected = player?.dbusName ?? "";
  }

  function seek(seconds) {
    const p = active;
    if (!p || !p.canSeek)
      return;
    p.position = Math.max(0, Math.min(p.length > 0 ? p.length - 1 : seconds, seconds));
  }

  Poller {
    id: poller
    command: "busctl --user list --acquired --no-legend --no-pager | awk '{print $1}' | grep '^org\\.mpris\\.MediaPlayer2\\.'"
    interval: 2000
  }
}
