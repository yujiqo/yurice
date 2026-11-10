pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property int users: 0
  property bool accept: false

  function acquire() {
    users++;
    if (!proc.running)
      proc.running = true;
  }

  function release() {
    users = Math.max(0, users - 1);
    if (users === 0 && proc.running)
      proc.write("quit\n");
  }

  Process {
    id: proc
    command: ["bluetoothctl", "--agent", "NoInputNoOutput"]
    stdinEnabled: true
    onRunningChanged: {
      if (running)
        write("default-agent\n");
      else if (root.users > 0)
        running = true;
    }
    stdout: SplitParser {
      splitMarker: "(yes/no)"
      onRead: {
        if (proc.running)
          proc.write(root.accept ? "yes\n" : "no\n");
      }
    }
  }
}
