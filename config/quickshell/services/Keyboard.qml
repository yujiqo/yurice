pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string capsPath: ""
  property int caps: -1

  function watch() {
    finder.running = true;
  }

  function shortName(name) {
    return name.slice(0, 2).toUpperCase();
  }

  Connections {
    target: Niri
    function onLayoutSwitched(index) {
      const name = Niri.layoutNames[index] ?? "";
      Notifications.notifyLocal("layout", "keyboard", name, "Layout " + root.shortName(name));
    }
  }

  Process {
    id: finder
    command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock 2>/dev/null | head -n 1"]
    stdout: StdioCollector {
      onStreamFinished: {
        const dir = text.trim();
        if (dir !== "")
          root.capsPath = dir + "/brightness";
      }
    }
  }

  FileView {
    id: capsFile
    path: root.capsPath
    printErrors: false
    onLoaded: {
      const next = parseInt(text().trim()) > 0 ? 1 : 0;
      if (root.caps !== -1 && next !== root.caps)
        Notifications.notifyLocal("caps", "keyboard_capslock", next ? "Caps Lock on" : "Caps Lock off");
      root.caps = next;
    }
  }

  Timer {
    interval: 150
    repeat: true
    running: root.capsPath !== ""
    onTriggered: capsFile.reload()
  }
}
