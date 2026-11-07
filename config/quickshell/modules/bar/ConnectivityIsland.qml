import QtQuick
import Quickshell.Bluetooth
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  open: current === "wifi" || current === "bluetooth"
  panel: current === "wifi" ? wifiPanel : current === "bluetooth" ? bluetoothPanel : null
  panelIndex: current === "bluetooth" ? 1 : 0

  readonly property var networkSegments: {
    const result = [];
    if (Network.ethernet)
      result.push(Utility.seg("settings_ethernet", "Wired", Theme.ethernet));
    if (Network.wifi)
      result.push(Utility.seg(Network.signalIcon(Network.wifiSignal), Network.wifiSsid, Theme.wifi));
    if (result.length === 0)
      result.push(Utility.seg("wifi_off", "Offline", Theme.off));
    return result;
  }

  readonly property var bluetoothSegment: {
    const adapter = Bluetooth.defaultAdapter;
    if (!adapter || !adapter.enabled)
      return Utility.seg("bluetooth_disabled", "Off", Theme.off);
    const connected = Bluetooth.devices.values.filter(d => d.connected);
    if (connected.length === 0)
      return Utility.seg("bluetooth", "Not connected", Theme.bluetooth);
    const name = connected[0].name || connected[0].deviceName;
    const extra = connected.length > 1 ? ` +${connected.length - 1}` : "";
    return Utility.seg("bluetooth_connected", name + extra, Theme.bluetooth);
  }

  Repeater {
    model: root.networkSegments

    Segment {
      required property var modelData
      icon: modelData.icon
      label: modelData.label
      color: modelData.color
      showLabel: root.expanded
      clickable: true
      onClicked: root.request("wifi")
      onPressedChanged: root.held = pressed
    }
  }

  Component {
    id: wifiPanel

    WifiPanel {}
  }

  Component {
    id: bluetoothPanel

    BluetoothPanel {}
  }

  Segment {
    icon: root.bluetoothSegment.icon
    label: root.bluetoothSegment.label
    color: root.bluetoothSegment.color
    showLabel: root.expanded
    clickable: true
    onClicked: root.request("bluetooth")
    onPressedChanged: root.held = pressed
  }
}
