pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string backlightDir: "/sys/class/backlight/intel_backlight"
  readonly property bool available: maxFile.loaded && curFile.loaded
  readonly property int percent: Math.round(parseInt(curFile.text()) / parseInt(maxFile.text()) * 100) || 0

  function step(up) {
    if (writer.running)
      return;
    writer.command = ["brightnessctl", "-c", "backlight", "-n", "1%", "-q", "s", up ? "5%+" : "5%-"];
    writer.running = true;
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
  }
}
