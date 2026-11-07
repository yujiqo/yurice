pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import qs.components

Singleton {
  id: root

  readonly property var liveNames: poller.value.split("\n").filter(n => n !== "")
  readonly property var players: Mpris.players.values.filter(p => liveNames.some(n => n === p.dbusName || n === "org.mpris.MediaPlayer2." + p.dbusName))
  readonly property var active: players.find(p => p.isPlaying) ?? null

  Poller {
    id: poller
    command: "busctl --user list --acquired --no-legend --no-pager | awk '{print $1}' | grep '^org\\.mpris\\.MediaPlayer2\\.'"
    interval: 2000
  }
}
