import QtQuick
import Quickshell.Services.UPower
import qs.theme
import qs.components

Pill {
  id: root

  readonly property var battery: UPower.displayDevice
  readonly property int percent: Math.round(battery.percentage * 100)
  readonly property bool plugged: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge

  readonly property string batteryIcon: {
    const p = percent;
    if (plugged)
      return Utility.pick(p, [[95, "battery_charging_full"], [90, "battery_charging_90"], [80, "battery_charging_80"], [60, "battery_charging_60"], [50, "battery_charging_50"], [30, "battery_charging_30"]], "battery_charging_20");
    if (p >= 95)
      return "battery_full";
    if (p < 10)
      return "battery_alert";
    return `battery_${Math.min(6, Math.floor(p / 100 * 7))}_bar`;
  }

  readonly property color batteryColor: plugged ? Theme.charging : Utility.pick(percent, [[20, Theme.good], [10, Theme.warn]], Theme.bad)

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

  segments: [Utility.seg(batteryIcon, percent + "%", batteryColor), profileSegment]
  clickable: true
  onClicked: mouse => root.cycleProfile(mouse.button === Qt.RightButton ? -1 : 1)
}
