pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property bool isOpen: false
  property string output: ""

  function open() {
    output = Niri.focusedOutput || (Quickshell.screens[0]?.name ?? "");
    isOpen = true;
  }

  function close() {
    isOpen = false;
  }

  function toggle() {
    if (isOpen)
      close();
    else
      open();
  }

  function run(action) {
    close();
    runner.command = ["systemctl", action];
    runner.running = true;
  }

  Process {
    id: runner
  }

  IpcHandler {
    target: "power"

    function toggle(): void {
      root.toggle();
    }
    function open(): void {
      root.open();
    }
    function close(): void {
      root.close();
    }
  }
}
