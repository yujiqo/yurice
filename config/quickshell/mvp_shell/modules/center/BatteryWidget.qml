// BatteryWidget.qml — UPower.displayDevice, same colors as the bar's battery Pill.
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.theme

RowLayout {
  id: root
  spacing: Theme.s3

  readonly property var bat: UPower.displayDevice
  readonly property bool charging: bat.state === UPowerDeviceState.Charging
  readonly property bool low: bat.percentage <= 0.2 && !charging

  function formatTime(seconds) {
    const h = Math.floor(seconds / 3600)
    const m = Math.round((seconds % 3600) / 60)
    return h > 0 ? h + "h " + m + "m" : m + "m"
  }

  Text {
    text: root.charging ? "⚡" : "🔋"
    color: root.charging ? Theme.ok : (root.low ? Theme.warn : Theme.text)
    font.pixelSize: Theme.fsLarge
  }

  ColumnLayout {
    spacing: 0

    Text {
      text: Math.round(root.bat.percentage * 100) + "%"
      color: root.charging ? Theme.ok : (root.low ? Theme.warn : Theme.text)
      font.pixelSize: Theme.fsNormal
    }
    Text {
      readonly property int seconds: root.charging ? root.bat.timeToFull : root.bat.timeToEmpty
      text: root.charging
        ? root.formatTime(seconds) + " until full"
        : root.formatTime(seconds) + " left"
      visible: seconds > 0
      color: Theme.textDim
      font.pixelSize: Theme.fsSmall
    }
  }
}
