pragma Singleton
import Quickshell
import QtQuick
import qs.components

Singleton {
  id: root

  readonly property var _lines: poller.value.split("\n")
  readonly property bool ethernet: parseInt(_lines[0]) > 0
  readonly property string _wifi: _lines[1] ?? ""
  readonly property bool wifi: _wifi !== ""
  readonly property int wifiSignal: wifi ? parseInt(_wifi.slice(0, _wifi.indexOf(":"))) : -1
  readonly property string wifiSsid: wifi ? _wifi.slice(_wifi.indexOf(":") + 1).replace(/\\:/g, ":") : ""

  Poller {
    id: poller
    command: "nmcli -t -f TYPE,STATE device | grep -c '^ethernet:connected'; " + "nmcli -t -f ACTIVE,SIGNAL,SSID device wifi list --rescan no | grep '^yes' | head -n1 | cut -d: -f2-"
    interval: 5000
  }
}
