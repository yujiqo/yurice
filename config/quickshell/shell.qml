import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

ShellRoot {
  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors { top: true; left: true; right: true }
      implicitHeight: 32
      color: "#1e1e2e"

      RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8

        Workspace { output: modelData.name }
        Item { Layout.fillWidth: true }
        Pill { text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm") }
        Item { Layout.fillWidth: true }
        Pill {
          id: wifi
          property string ssid: ""
          text: ssid === "" ? "📶 off" : "📶 " + ssid

          Process {
            id: proc
            command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2"]
            stdout: StdioCollector {
              onStreamFinished: wifi.ssid = text.trim()
            }
          }

          Timer {
            interval: 5000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: proc.running = true
          }
        }
        Pill {
          readonly property var bat: UPower.displayDevice
          text: (bat.state === UPowerDeviceState.Charging ? "⚡ " : "🔋 ") + Math.round(bat.percentage * 100) + "%"
          fg: bat.percentage === 0.2 ? "#f38ba8": "#cdd6f4"
        }
      }
    }
  }
}
