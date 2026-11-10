pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Networking
import QtQuick
import qs.components

Singleton {
  id: root

  readonly property var devices: Networking.devices.values
  readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
  readonly property var wiredDevice: {
    const wired = devices.filter(d => d.type === DeviceType.Wired);
    return wired.find(d => d.connected) ?? wired.find(d => d.hasLink) ?? wired[0] ?? null;
  }

  readonly property bool wifiEnabled: Networking.wifiEnabled
  readonly property var wifiNetworks: wifiDevice?.networks.values ?? []
  readonly property var wifiNetwork: wifiNetworks.find(n => n.connected) ?? null
  readonly property bool wifi: wifiNetwork !== null
  readonly property int wifiSignal: wifi ? percentOf(wifiNetwork.signalStrength) : -1
  readonly property string wifiSsid: wifiNetwork?.name ?? ""
  readonly property bool ethernet: wiredDevice?.connected ?? false

  function listNetworks() {
    return wifiNetworks.filter(n => n.name !== "").sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (Math.round(b.signalStrength * 5) - Math.round(a.signalStrength * 5)) || a.name.localeCompare(b.name));
  }

  function percentOf(strength) {
    return Math.round(strength <= 1 ? strength * 100 : strength);
  }

  function signalIcon(percent) {
    return Utility.pick(percent, [[80, "network_wifi"], [60, "network_wifi_3_bar"], [40, "network_wifi_2_bar"], [20, "network_wifi_1_bar"]], "signal_wifi_0_bar");
  }

  function isOpen(network) {
    return network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe;
  }

  function setWifiEnabled(enabled) {
    Networking.wifiEnabled = enabled;
  }

  function setScanning(enabled) {
    if (wifiDevice)
      wifiDevice.scannerEnabled = enabled;
  }

  function toggleWired() {
    if (!wiredDevice)
      return;
    if (wiredDevice.connected)
      wiredDevice.disconnect();
    else
      wiredDevice.network?.connect();
  }
}
