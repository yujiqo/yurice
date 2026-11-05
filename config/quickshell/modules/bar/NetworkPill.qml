import QtQuick
import qs.theme
import qs.components
import qs.services

Pill {
  segments: {
    const result = [];
    if (Network.ethernet)
      result.push(Utility.seg("settings_ethernet", "Wired", Theme.ethernet));
    if (Network.wifi) {
      const icon = Utility.pick(Network.wifiSignal, [[80, "network_wifi"], [60, "network_wifi_3_bar"], [40, "network_wifi_2_bar"], [20, "network_wifi_1_bar"]], "signal_wifi_0_bar");
      result.push(Utility.seg(icon, Network.wifiSsid, Theme.wifi));
    }
    if (result.length === 0)
      result.push(Utility.seg("wifi_off", "Not connected", Theme.off));
    return result;
  }
}
