pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string hostname: ""
  property string kernel: ""
  property string nixosVersion: ""
  property int generation: 0
  property date generationDate: new Date(0)
  property date bootTime: new Date()
  property bool loaded: false

  readonly property string uptime: formatUptime((Clock.date - bootTime) / 1000)
  readonly property string version: {
    const parts = nixosVersion.split(".");
    if (parts.length < 4)
      return nixosVersion;
    return `${parts[0]}.${parts[1]} · ${parts[3]}`;
  }

  function formatUptime(seconds) {
    const total = Math.max(0, Math.floor(seconds / 60));
    const days = Math.floor(total / 1440);
    const hours = Math.floor(total % 1440 / 60);
    const minutes = total % 60;
    if (days > 0)
      return `${days}d ${hours}h ${minutes}m`;
    if (hours > 0)
      return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  }

  function refresh() {
    if (!reader.running)
      reader.running = true;
  }

  Process {
    id: reader
    command: ["sh", "-c", `
      echo "$(cat /proc/sys/kernel/hostname)"
      echo "$(uname -r)"
      echo "$(cat /run/current-system/nixos-version 2>/dev/null || nixos-version 2>/dev/null)"
      echo "$(cut -d' ' -f1 /proc/uptime)"
      link=$(readlink /nix/var/nix/profiles/system)
      echo "$link"
      echo "$(stat -c %Y "/nix/var/nix/profiles/$link" 2>/dev/null || echo 0)"
    `]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n");
        root.hostname = (lines[0] ?? "").trim();
        root.kernel = (lines[1] ?? "").trim();
        root.nixosVersion = (lines[2] ?? "").trim();
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
