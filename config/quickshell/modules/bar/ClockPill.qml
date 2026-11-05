import Quickshell
import QtQuick
import qs.theme
import qs.components

Pill {
  icon: "schedule"
  iconColor: Theme.clock
  label: Qt.formatDateTime(clock.date, "HH:mm ddd dd MMM")

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
