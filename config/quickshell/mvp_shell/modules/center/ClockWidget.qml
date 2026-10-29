// ClockWidget.qml — bigger time/date display for the center panel. shell.qml's bar keeps its
// own small date Pill; this is a separate SystemClock instance, not a shared one.
import QtQuick
import Quickshell
import qs.theme

Column {
  id: root
  spacing: Theme.s1

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  Text {
    text: Qt.formatDateTime(clock.date, "HH:mm:ss")
    color: Theme.text
    font.pixelSize: Theme.fsLarge
    font.bold: true
  }
  Text {
    text: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
    color: Theme.textDim
    font.pixelSize: Theme.fsSmall
  }
}
