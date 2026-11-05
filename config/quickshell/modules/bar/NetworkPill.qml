import QtQuick
import qs.theme
import qs.components

Pill {
  id: root

  segments: {
    const lines = network.value.split("\n");
    const ethernet = parseInt(lines[0]) > 0;
    const wifi = lines[1] ?? "";
    const result = [];

    if (ethernet)
      result.push(Utility.seg("settings_ethernet", "Wired", Theme.ethernet));
    if (wifi !== "") {
      const sep = wifi.indexOf(":");
      const signal = parseInt(wifi.slice(0, sep));
      const ssid = wifi.slice(sep + 1).replace(/\\:/g, ":");
      const icon = Utility.pick(signal, [[80, "network_wifi"], [60, "network_wifi_3_bar"], [40, "network_wifi_2_bar"], [20, "network_wifi_1_bar"]], "signal_wifi_0_bar");
      result.push(Utility.seg(icon, ssid, Theme.wifi));
    }
    if (result.length === 0)
      result.push(Utility.seg("wifi_off", "Not connected", Theme.off));
    return result;
  }

  Poller {
    id: network
    command: "nmcli -t -f TYPE,STATE device | grep -c '^ethernet:connected'; " + "nmcli -t -f ACTIVE,SIGNAL,SSID device wifi list --rescan no | grep '^yes' | head -n1 | cut -d: -f2-"
    interval: 5000
  }
}
