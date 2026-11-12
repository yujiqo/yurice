pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.UPower
import qs.theme
import qs.components
import qs.services

Island {
  id: root

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

  panels: ({
      battery: batteryPanel
    })
  panelWidth: 340
  spacing: 0
  clickable: true
  onClicked: mouse => mouse.button === Qt.RightButton ? cycleProfile(1) : request("battery")

  Component {
    id: batteryPanel

    BatteryPanel {}
  }

  Segment {
    icon: Battery.icon
    label: Battery.percent + "%"
    color: Battery.color
    showLabel: true
  }

  Reveal {
    shown: Caffeine.active
    leading: Theme.pillSegmentGap

    Segment {
      icon: "coffee"
      color: Theme.primary
    }
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
