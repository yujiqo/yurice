import Quickshell
import QtQuick
import Quickshell.Io

ShellRoot {
  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors { top: true; left: true; right: true }
      implicitHeight: 32
      color: "#1e1e2e"

      Text {
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd dd MMM HH:mm")
        color: "#cdd6f4"
        font.pixelSize: 14
      }
    }
  }
}
