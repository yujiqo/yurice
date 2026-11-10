pragma ComponentBehavior: Bound
import Quickshell.Io
import QtQuick

FileView {
  id: root

  readonly property var lines: text().split("\n").map(line => line.trim())

  function write(content) {
    writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && umask 077 && printf %s "$2" > "$1"', "sh", path, content];
    writer.running = true;
  }

  watchChanges: true
  printErrors: false
  onFileChanged: reload()

  property Process writer: Process {
    onExited: root.reload()
  }
}
