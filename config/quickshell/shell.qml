import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

PanelWindow {
  id: bar

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: 40
  color: "transparent"

  Poller {
    id: clock
    command: "date +%H:%M"
    interval: 60000
  }

  Poller {
    id: network
    command: "nmcli -t -f NAME connection show --active | head -n1"
    interval: 5000
  }

  Poller {
    id: bluetooth
    command: "bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off"
    interval: 5000
  }

  Poller {
    id: volume
    command: "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf\"%d\", $2*100}'"
    interval: 1000
  }

  Poller {
    id: battery
    command: "cat /sys/class/power_supply/BAT0/capacity"
    interval: 30000
  }

  readonly property var player: Mpris.players.values.find(player => player.isPlaying) ?? Mpris.players.values[0] ?? null

  RowLayout {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 10
    spacing: 5

    Pill {
      icon: "music_note"
      maxLabelWidth: 300
      label: bar.player ? `${bar.player.trackArtist || "Unknown"} — ${bar.player.trackTitle || ""}` : "Nothing is playing"
    }
  }

  RowLayout {
    anchors.centerIn: parent
    anchors.verticalCenter: parent.verticalCenter

    Pill {
      icon: "schedule"
      label: clock.value
    }
  }

  RowLayout {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: 10
    spacing: 5

    Pill {
      icon: "network_wifi"
      label: network.value
    }

    Pill {
      icon: "bluetooth"
      label: bluetooth.value
    }

    Pill {
      icon: "volume_up"
      label: volume.value + "%"
    }

    Pill {
      icon: "battery_full"
      label: battery.value + "%"
    }
  }
}
