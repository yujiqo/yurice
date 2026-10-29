import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.modules.bar
import qs.modules.center
import qs.modules.demo

ShellRoot {
  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  DemoPanels {}

  PopupPanel {
    edge: "center"
    ipcTarget: "center"
    content: Component { CenterPanel {} }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors { top: true; left: true; right: true }
      implicitHeight: Theme.s5
      color: Theme.bg

      RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.s2
        spacing: Theme.s3

        Workspace { output: modelData.name }
        Item { Layout.fillWidth: true }
        Pill { text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm") }
        Item { Layout.fillWidth: true }
        Pill {
          id: wifi
          property string netStatus: "📶 off"
          text: netStatus

          Process {
            id: proc
            command: ["sh", "-c", "
              ssid=\$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2);
              if [ -n \"\$ssid\" ]; then
                echo \"📶 \$ssid\";
              elif nmcli -t -f TYPE,STATE dev | grep -q '^ethernet:connected'; then
                echo \"󰈀  ethernet\";
              else
                echo \"📶 off\";
              fi
            "]
            stdout: StdioCollector {
              onStreamFinished: wifi.netStatus = text.trim()
            }
          }

          Timer {
            interval: 3000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: proc.running = true
          }
        }
        Pill {
          readonly property var bat: UPower.displayDevice
          text: (bat.state === UPowerDeviceState.Charging ? "⚡ " : "🔋 ") + Math.round(bat.percentage * 100) + "%"
          fg: bat.state === UPowerDeviceState.Charging ? Theme.ok: (bat.percentage === 0.2 ? Theme.warn : Theme.text)
        }
      }
    }
  }
}
