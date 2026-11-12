pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import qs.components

Singleton {
  id: root

  property string hostname: ""
  property string kernel: ""
  property string osVersion: ""
  property string osId: ""
  property string osName: ""
  readonly property bool nixos: osId === "nixos"
  property int generation: 0
  property date generationDate: new Date(0)
  property date bootTime: new Date()
  property bool loaded: false

  readonly property string uptime: Utility.formatDuration((Clock.date - bootTime) / 1000)
  readonly property string version: {
    const parts = osVersion.split(".");
    if (!nixos || parts.length < 4)
      return osVersion;
    return `${parts[0]}.${parts[1]} · ${parts[3]}`;
  }

  function refresh() {
    if (!reader.running)
      reader.running = true;
  }

  Process {
    id: reader
    command: ["sh", Paths.scripts + "/system-info.sh"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n");
        root.hostname = (lines[0] ?? "").trim();
        root.kernel = (lines[1] ?? "").trim();
        root.osVersion = (lines[2] ?? "").trim();
        root.osId = (lines[6] ?? "").trim();
        root.osName = (lines[7] ?? "").trim();
        const up = parseFloat(lines[3]);
        if (!isNaN(up))
          root.bootTime = new Date(Date.now() - up * 1000);
        const match = (lines[4] ?? "").match(/system-(\d+)-link/);
        root.generation = match ? parseInt(match[1]) : 0;
        root.generationDate = new Date(parseInt(lines[5]) * 1000 || 0);
        root.loaded = true;
      }
    }
  }

  Component.onCompleted: refresh()
}
