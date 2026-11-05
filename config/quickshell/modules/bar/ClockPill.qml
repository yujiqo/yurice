import QtQuick
import qs.theme
import qs.components
import qs.services

Pill {
  icon: "schedule"
  iconColor: Theme.clock
  label: Qt.formatDateTime(Clock.date, "HH:mm ddd dd MMM")
}
