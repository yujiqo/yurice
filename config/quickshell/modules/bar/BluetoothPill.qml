import QtQuick
import Quickshell.Bluetooth
import qs.theme
import qs.components

Pill {
  segments: [segment]

  readonly property var segment: {
    const adapter = Bluetooth.defaultAdapter;
    if (!adapter || !adapter.enabled)
      return Utility.seg("bluetooth_disabled", "Off", Theme.off);

    const connected = Bluetooth.devices.values.filter(d => d.connected);
    if (connected.length === 0)
      return Utility.seg("bluetooth", "No connected devices", Theme.bluetooth);

    const name = connected[0].name || connected[0].deviceName;
    const extra = connected.length > 1 ? ` +${connected.length - 1}` : "";
    return Utility.seg("bluetooth_connected", name + extra, Theme.bluetooth);
  }
}
