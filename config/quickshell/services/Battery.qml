pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs.theme
import qs.components

Singleton {
  id: root

  readonly property var display: UPower.displayDevice
  readonly property bool available: UPower.devices.values.some(d => d.isLaptopBattery)
  readonly property var device: UPower.devices.values.find(d => d.isLaptopBattery) ?? display
  readonly property string sysfsDir: device?.nativePath ? "/sys/class/power_supply/" + device.nativePath + "/" : ""

  readonly property int percent: Math.round(display.percentage * 100)
  readonly property bool charging: display.state === UPowerDeviceState.Charging
  readonly property bool full: display.state === UPowerDeviceState.FullyCharged
  readonly property bool plugged: !UPower.onBattery || charging || full

  readonly property real energy: device.energy
  readonly property real energyFull: device.energyCapacity
  readonly property real rate: Math.abs(device.changeRate)
  readonly property real timeToEmpty: display.timeToEmpty
  readonly property real timeToFull: display.timeToFull

  readonly property real designWh: (parseInt(designFile.text()) || 0) / 1e6
  readonly property int cycles: parseInt(cyclesFile.text()) || -1
  readonly property int limit: parseInt(limitFile.text()) || -1
  readonly property string technology: technologyFile.text().trim()
  readonly property string vendor: vendorFile.text().trim()
  readonly property real health: device.healthSupported && device.healthPercentage > 0 ? device.healthPercentage : designWh > 0 ? energyFull / designWh * 100 : -1

  readonly property string icon: {
    if (plugged)
      return Utility.pick(percent, [[95, "battery_charging_full_2"], [80, "battery_charging_80_2"], [50, "battery_charging_50_2"], [30, "battery_charging_30_2"]], "battery_charging_20_2");
    return Utility.pick(percent, [[95, "battery_android_full"], [85, "battery_android_5"], [70, "battery_android_4"], [50, "battery_android_3"], [30, "battery_android_2"], [10, "battery_android_1"]], "battery_android_alert");
  }

  readonly property color color: plugged ? Theme.charging : Utility.pick(percent, [[20, Theme.good], [10, Theme.warn]], Theme.bad)

  readonly property string status: {
    if (charging)
      return timeToFull > 0 ? `Full in ${Utility.formatDuration(timeToFull)}` : "Charging";
    if (full)
      return "Fully charged";
    if (plugged)
      return limit > 0 && percent >= limit - 1 ? `Plugged in · held at ${limit}%` : "Plugged in · not charging";
    return timeToEmpty > 0 ? `${Utility.formatDuration(timeToEmpty)} remaining` : "On battery";
  }

  FileView {
    id: designFile
    path: root.sysfsDir ? root.sysfsDir + "energy_full_design" : ""
    printErrors: false
  }

  FileView {
    id: cyclesFile
    path: root.sysfsDir ? root.sysfsDir + "cycle_count" : ""
    printErrors: false
  }

  FileView {
    id: limitFile
    path: root.sysfsDir ? root.sysfsDir + "charge_control_end_threshold" : ""
    printErrors: false
  }

  FileView {
    id: technologyFile
    path: root.sysfsDir ? root.sysfsDir + "technology" : ""
    printErrors: false
  }

  FileView {
    id: vendorFile
    path: root.sysfsDir ? root.sysfsDir + "manufacturer" : ""
    printErrors: false
  }
}
