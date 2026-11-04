import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

PanelWindow {
  id: bar

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: 40
  color: "transparent"

  readonly property color colClock: "#f5c26b"
  readonly property color colMusic: "#f78fb3"
  readonly property color colWifi: "#6bb8ff"
  readonly property color colEthernet: "#a0a8a8"
  readonly property color colBluetooth: "#4d8eff"
  readonly property color colOff: "#5c6664"
  readonly property color colVolume: "#c792ea"
  readonly property color colGood: "#7bd88f"
  readonly property color colCharging: "#f9e26b"
  readonly property color colWarn: "#ff9e64"
  readonly property color colBad: "#ff6b6b"
  readonly property color colBalanced: "#7fd1c7"

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Poller {
    id: network
    command: "nmcli -t -f TYPE,STATE device | grep -c '^ethernet:connected'; " + "nmcli -t -f ACTIVE,SIGNAL,SSID device wifi list --rescan no | grep '^yes' | head -n1 | cut -d: -f2-"
    interval: 5000
  }

  readonly property var player: Mpris.players.values.find(player => player.isPlaying) ?? Mpris.players.values[0] ?? null

  readonly property var networkSegments: {
    const lines = network.value.split("\n");
    const ethernet = parseInt(lines[0]) > 0;
    const wifi = lines[1] ?? "";
    const segments = [];

    if (ethernet)
      segments.push({
        icon: "settings_ethernet",
        label: "Wired",
        color: colEthernet
      });
    if (wifi !== "") {
      const sep = wifi.indexOf(":");
      const signal = parseInt(wifi.slice(0, sep));
      const ssid = wifi.slice(sep + 1).replace(/\\:/g, ":");
      const icon = signal >= 80 ? "network_wifi" : signal >= 60 ? "network_wifi_3_bar" : signal >= 40 ? "network_wifi_2_bar" : signal >= 20 ? "network_wifi_1_bar" : "signal_wifi_0_bar";
      segments.push({
        icon: icon,
        label: ssid,
        color: colWifi
      });
    }
    if (segments.length === 0)
      segments.push({
        icon: "wifi_off",
        label: "Not connected",
        color: colOff
      });
    return segments;
  }

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool muted: sink?.audio?.muted ?? false
  readonly property int volumePercent: Math.round((sink?.audio?.volume ?? 0) * 100)

  PwObjectTracker {
    objects: [bar.sink]
  }

  readonly property var volumeSegment: {
    if (muted || volumePercent === 0)
      return {
        icon: "volume_off",
        label: muted ? "Muted" : "0%",
        color: colOff
      };
    const icon = volumePercent < 33 ? "volume_mute" : volumePercent < 66 ? "volume_down" : "volume_up";
    return {
      icon: icon,
      label: volumePercent + "%",
      color: colVolume
    };
  }

  readonly property var bluetoothSegment: {
    const adapter = Bluetooth.defaultAdapter;
    if (!adapter || !adapter.enabled)
      return {
        icon: "bluetooth_disabled",
        label: "Off",
        color: colOff
      };

    const connected = Bluetooth.devices.values.filter(d => d.connected);
    if (connected.length === 0)
      return {
        icon: "bluetooth",
        label: "No connected devices",
        color: colBluetooth
      };

    const name = connected[0].name || connected[0].deviceName;
    const extra = connected.length > 1 ? ` +${connected.length - 1}` : "";
    return {
      icon: "bluetooth_connected",
      label: name + extra,
      color: colBluetooth
    };
  }

  readonly property var battery: UPower.displayDevice
  readonly property int batteryPercent: Math.round(battery.percentage * 100)
  readonly property bool batteryPlugged: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge

  function batteryIcon(p, plugged) {
    if (plugged) {
      if (p >= 95)
        return "battery_charging_full";
      for (const step of [90, 80, 60, 50, 30, 20]) {
        if (p >= step)
          return `battery_charging_${step}`;
      }
      return "battery_charging_20";
    }
    if (p >= 95)
      return "battery_full";
    if (p < 10)
      return "battery_alert";
    return `battery_${Math.min(6, Math.floor(p / 100 * 7))}_bar`;
  }

  readonly property var profiles: PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced]

  function cycleProfile(step) {
    const i = profiles.indexOf(PowerProfiles.profile);
    PowerProfiles.profile = profiles[(i + step + profiles.length) % profiles.length];
  }

  readonly property var profileSegment: {
    switch (PowerProfiles.profile) {
    case PowerProfile.PowerSaver:
      return {
        icon: "eco",
        label: "power-saver",
        color: colGood
      };
    case PowerProfile.Performance:
      return {
        icon: "speed",
        label: "performance",
        color: colWarn
      };
    default:
      return {
        icon: "balance",
        label: "balanced",
        color: colBalanced
      };
    }
  }

  RowLayout {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 10
    spacing: 5

    Pill {
      icon: "schedule"
      iconColor: bar.colClock
      label: Qt.formatDateTime(clock.date, "HH:mm ddd dd MMM")
    }

    Pill {
      icon: "music_note"
      iconColor: bar.colMusic
      maxLabelWidth: 300
      label: bar.player ? `${bar.player.trackArtist || "Unknown"} — ${bar.player.trackTitle || ""}` : "Nothing is playing"
    }
  }

  Workspaces {
    anchors.centerIn: parent
    output: bar.screen?.name ?? ""
  }

  RowLayout {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: 10
    spacing: 5

    Pill {
      segments: bar.networkSegments
    }

    Pill {
      segments: [bar.bluetoothSegment]
    }

    Pill {
      segments: [bar.volumeSegment]
      clickable: true
      onClicked: if (bar.sink?.audio)
        bar.sink.audio.muted = !bar.sink.audio.muted

      WheelHandler {
        onWheel: event => {
          if (!bar.sink?.audio)
            return;
          const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
          bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + step));
        }
      }
    }

    Pill {
      clickable: true
      onClicked: mouse => bar.cycleProfile(mouse.button === Qt.RightButton ? -1 : 1)
      segments: [
        {
          icon: bar.batteryIcon(bar.batteryPercent, bar.batteryPlugged),
          label: bar.batteryPercent + "%",
          color: bar.batteryPlugged ? bar.colCharging : bar.batteryPercent < 10 ? bar.colBad : bar.batteryPercent < 20 ? bar.colWarn : bar.colGood
        },
        bar.profileSegment]
    }
  }
}
