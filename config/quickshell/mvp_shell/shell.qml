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
          id: powerProfile
          property string profile: "?"
          property var profiles: []
          text: "󰓅  " + profile

          // `powerprofilesctl list` prints one "  name:" header per profile, the active one as "* name:"
          Process {
            id: profileProc
            command: ["powerprofilesctl", "list"]
            stdout: StdioCollector {
              onStreamFinished: {
                const found = []
                let active = "?"
                for (const line of text.split("\n")) {
                  const m = line.match(/^([* ]) (\S+):$/)
                  if (!m) continue
                  found.push(m[2])
                  if (m[1] === "*") active = m[2]
                }
                powerProfile.profiles = found
                powerProfile.profile = active
              }
            }
          }

          Process {
            id: profileSet
            onExited: profileProc.running = true
          }

          // hover/press feedback, since this is the only clickable Pill in the bar
          color: profileMouse.containsMouse ? Theme.surfaceAlt : Theme.surface
          scale: profileMouse.pressed ? 0.94 : 1
          Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
          Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }

          // left click: next profile, right click: previous
          MouseArea {
            id: profileMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              const list = powerProfile.profiles
              if (list.length === 0 || profileSet.running) return
              const step = mouse.button === Qt.RightButton ? -1 : 1
              const next = list[(list.indexOf(powerProfile.profile) + step + list.length) % list.length]
              powerProfile.profile = next
              profileSet.command = ["powerprofilesctl", "set", next]
              profileSet.running = true
            }
          }

          Timer {
            interval: 3000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: profileProc.running = true
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
