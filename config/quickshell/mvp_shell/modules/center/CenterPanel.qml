// CenterPanel.qml — content for the "center" PopupPanel (M3a): clock, battery, brightness,
// volume. Wifi/bluetooth status + device pickers are M3b, not here yet.
import QtQuick
import QtQuick.Layouts
import qs.theme

Rectangle {
  id: root
  implicitWidth: 320
  implicitHeight: column.implicitHeight + Theme.s4 * 2
  radius: Theme.rLarge
  color: Theme.bg
  border.color: Theme.border
  border.width: 1

  ColumnLayout {
    id: column
    anchors.fill: parent
    anchors.margins: Theme.s4
    spacing: Theme.s4

    ClockWidget {}
    BatteryWidget {}
    BrightnessWidget { Layout.fillWidth: true }
    VolumeWidget { Layout.fillWidth: true }
  }
}
