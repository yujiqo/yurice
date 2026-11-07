import QtQuick
import Quickshell.Services.UPower
import qs.theme
import qs.components

Island {
  id: root

  readonly property var battery: UPower.displayDevice
  readonly property int percent: Math.round(battery.percentage * 100)
  readonly property bool plugged: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge

  readonly property string batteryIcon: {
    if (plugged)
      return Utility.pick(percent, [[95, "battery_charging_full_2"], [80, "battery_charging_80_2"], [50, "battery_charging_50_2"], [30, "battery_charging_30_2"]], "battery_charging_20_2");
    return Utility.pick(percent, [[95, "battery_android_full"], [85, "battery_android_5"], [70, "battery_android_4"], [50, "battery_android_3"], [30, "battery_android_2"], [10, "battery_android_1"]], "battery_android_alert");
  }

  readonly property color batteryColor: plugged ? Theme.charging : Utility.pick(percent, [[20, Theme.good], [10, Theme.warn]], Theme.bad)

  readonly property var profiles: PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced]

  readonly property var profile: {
    switch (PowerProfiles.profile) {
    case PowerProfile.PowerSaver:
      return Utility.seg("eco", "power-saver", Theme.good);
    case PowerProfile.Performance:
      return Utility.seg("speed", "performance", Theme.warn);
    default:
      return Utility.seg("balance", "balanced", Theme.balanced);
    }
  }

  function cycleProfile(step) {
    const i = profiles.indexOf(PowerProfiles.profile);
    PowerProfiles.profile = profiles[(i + step + profiles.length) % profiles.length];
  }

  spacing: 0
  clickable: true
  onClicked: mouse => cycleProfile(mouse.button === Qt.RightButton ? -1 : 1)

  Segment {
    icon: root.batteryIcon
    label: root.percent + "%"
    color: root.batteryColor
    showLabel: true
  }

  Reveal {
    shown: root.expanded
    leading: Theme.pillSegmentGap

    Segment {
      icon: root.profile.icon
      label: root.profile.label
      color: root.profile.color
      showLabel: true
    }
  }
}
