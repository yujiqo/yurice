pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

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

  function run(action, args) {
    close();
    runner.command = ["systemctl", action].concat(args ?? []);
    runner.running = true;
  }

  property bool loggingOut: false
  property real outro: 0

  function logout() {
    close();
    if (loggingOut)
      return;
    loggingOut = true;
    outroAnim.start();
  }

  NumberAnimation {
    id: outroAnim
    target: root
    property: "outro"
    to: 1
    duration: Theme.animLock
    easing.type: Easing.InOutCubic
    onFinished: Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"])
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
