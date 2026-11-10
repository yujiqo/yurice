pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

Singleton {
  id: root

  property bool isOpen: false
  property string output: ""
  property bool loggingOut: false
  property real outro: 0
  property bool firmwareAvailable: false
  readonly property string userName: Quickshell.env("USER")

  function open() {
    output = Niri.activeOutput;
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

  function power(action) {
    if (action === "firmware")
      run("reboot", ["--firmware-setup"]);
    else
      run(action);
  }

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
    easing.type: Theme.easeInOut
    onFinished: Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"])
  }

  Process {
    running: true
    command: ["test", "-d", "/sys/firmware/efi"]
    onExited: code => root.firmwareAvailable = code === 0
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
