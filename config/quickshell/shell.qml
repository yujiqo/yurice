import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Io
import qs.theme
import qs.components
import qs.modules.bar

PanelWindow {
  id: bar

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: Theme.barHeight
  margins.top: Theme.barMarginTop
  color: "transparent"

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
      segments.push(Utility.seg("settings_ethernet", "Wired", Theme.ethernet));
    if (wifi !== "") {
      const sep = wifi.indexOf(":");
      const signal = parseInt(wifi.slice(0, sep));
      const ssid = wifi.slice(sep + 1).replace(/\\:/g, ":");
      const icon = Utility.pick(signal, [[80, "network_wifi"], [60, "network_wifi_3_bar"], [40, "network_wifi_2_bar"], [20, "network_wifi_1_bar"]], "signal_wifi_0_bar");
      segments.push(Utility.seg(icon, ssid, Theme.wifi));
    }
    if (segments.length === 0)
      segments.push(Utility.seg("wifi_off", "Not connected", Theme.off));
    return segments;
  }

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool muted: sink?.audio?.muted ?? false
  readonly property int volumePercent: Math.round((sink?.audio?.volume ?? 0) * 100)

  readonly property bool wiredHeadphones: {
    const props = sink?.properties ?? {};
    if (String(props["device.api"] ?? "") !== "alsa")
      return false;
    const icon = String(props["device.icon_name"] ?? props["device.icon-name"] ?? "").toLowerCase();
    const name = String(props["node.nick"] ?? sink?.nickname ?? sink?.name ?? "").toLowerCase();
    return icon === "audio-headphones" || name.includes("headphone");
  }

  PwObjectTracker {
    objects: [bar.sink]
  }

  readonly property var volumeSegment: {
    if (wiredHeadphones)
      return muted ? Utility.seg("headset_off", "Muted", Theme.off) : Utility.seg("headphones", volumePercent + "%", Theme.volume);
    if (muted || volumePercent === 0)
      return Utility.seg("volume_off", muted ? "Muted" : "0%", Theme.off);
    const icon = Utility.pick(volumePercent, [[66, "volume_up"], [33, "volume_down"]], "volume_mute");
    return Utility.seg(icon, volumePercent + "%", Theme.volume);
  }

  readonly property string backlightDir: "/sys/class/backlight/intel_backlight"

  FileView {
    id: brightnessMax
    path: bar.backlightDir + "/max_brightness"
  }

  FileView {
    id: brightnessCur
    path: bar.backlightDir + "/actual_brightness"
    watchChanges: true
    onFileChanged: reload()
  }

  readonly property bool hasBacklight: brightnessMax.loaded && brightnessCur.loaded
  readonly property int brightnessPercent: Math.round(parseInt(brightnessCur.text()) / parseInt(brightnessMax.text()) * 100) || 0

  readonly property var brightnessSegment: {
    const icon = Utility.pick(brightnessPercent, [[66, "brightness_high"], [33, "brightness_medium"]], "brightness_low");
    return Utility.seg(icon, brightnessPercent + "%", Theme.brightness);
  }

  Process {
    id: brightnessWrite
  }

  readonly property var bluetoothSegment: {
    const adapter = Bluetooth.defaultAdapter;
    if (!adapter || !adapter.enabled)
      return Utility.seg("bluetooth_disabled", "Off", Theme.off);

    const connected = Bluetooth.devices.values.filter(d => d.connected);
    if (connected.length === 0)
      return Utility.seg("bluetooth", "No connected devices", Theme.bluetooth);

    const name = connected[0].name || connected[0].deviceName;
    const extra = connected.length > 1 ? ` +${connected.length - 1}` : "";
    return Utility.seg("bluetooth_connected", name + extra, Theme.bluetooth);
  }

  readonly property var battery: UPower.displayDevice
  readonly property int batteryPercent: Math.round(battery.percentage * 100)
  readonly property bool batteryPlugged: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge

  readonly property string batteryIcon: {
    const p = batteryPercent;
    if (batteryPlugged)
      return Utility.pick(p, [[95, "battery_charging_full"], [90, "battery_charging_90"], [80, "battery_charging_80"], [60, "battery_charging_60"], [50, "battery_charging_50"], [30, "battery_charging_30"]], "battery_charging_20");
    if (p >= 95)
      return "battery_full";
    if (p < 10)
      return "battery_alert";
    return `battery_${Math.min(6, Math.floor(p / 100 * 7))}_bar`;
  }

  readonly property color batteryColor: batteryPlugged ? Theme.charging : Utility.pick(batteryPercent, [[20, Theme.good], [10, Theme.warn]], Theme.bad)

  readonly property var batterySegment: Utility.seg(batteryIcon, batteryPercent + "%", batteryColor)

  readonly property var profiles: PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced]

  function cycleProfile(step) {
    const i = profiles.indexOf(PowerProfiles.profile);
    PowerProfiles.profile = profiles[(i + step + profiles.length) % profiles.length];
  }

  readonly property var profileSegment: {
    switch (PowerProfiles.profile) {
    case PowerProfile.PowerSaver:
      return Utility.seg("eco", "power-saver", Theme.good);
    case PowerProfile.Performance:
      return Utility.seg("speed", "performance", Theme.warn);
    default:
      return Utility.seg("balance", "balanced", Theme.balanced);
    }
  }

  RowLayout {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Theme.barMargin
    spacing: Theme.barGap

    Pill {
      icon: "schedule"
      iconColor: Theme.clock
      label: Qt.formatDateTime(clock.date, "HH:mm ddd dd MMM")
    }

    Pill {
      icon: "music_note"
      iconColor: Theme.music
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
    anchors.rightMargin: Theme.barMargin
    spacing: Theme.barGap

    Pill {
      segments: bar.networkSegments
    }

    Pill {
      segments: [bar.bluetoothSegment]
    }

    Pill {
      visible: bar.hasBacklight
      segments: [bar.brightnessSegment]

      WheelHandler {
        onWheel: event => {
          if (brightnessWrite.running)
            return;
          const step = event.angleDelta.y > 0 ? "5%+" : "5%-";
          brightnessWrite.command = ["brightnessctl", "-c", "backlight", "-n", "1%", "-q", "s", step];
          brightnessWrite.running = true;
        }
      }
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
      segments: [bar.batterySegment, bar.profileSegment]
    }
  }
}
