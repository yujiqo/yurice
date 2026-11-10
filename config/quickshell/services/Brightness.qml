pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string backlightDir: "/sys/class/backlight/intel_backlight"
  readonly property bool available: maxFile.loaded && curFile.loaded
  readonly property int percent: Math.round(parseInt(curFile.text()) / parseInt(maxFile.text()) * 100) || 0

  property string pending: ""

  function run(arg) {
    if (writer.running) {
      pending = arg;
      return;
    }
    writer.command = ["brightnessctl", "-c", "backlight", "--min-value=1%", "-q", "s", arg];
    writer.running = true;
  }

  function step(up) {
    run(up ? "5%+" : "5%-");
  }

  function set(value) {
    run(Math.round(Math.max(0.01, Math.min(1, value)) * 100) + "%");
  }

  FileView {
    id: maxFile
    path: root.backlightDir + "/max_brightness"
  }

  FileView {
    id: curFile
    path: root.backlightDir + "/actual_brightness"
    watchChanges: true
    onFileChanged: reload()
  }

  Process {
    id: writer
    onExited: {
      if (root.pending !== "") {
        const arg = root.pending;
        root.pending = "";
        root.run(arg);
      }
    }
  }
}
