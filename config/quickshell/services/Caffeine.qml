pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property bool active: false
  property bool releasing: false
  property var pending: null

  function toggle() {
    active = !active;
  }

  function set(on) {
    active = on;
  }

  function release(callback) {
    if (!inhibitor.running) {
      callback();
      return;
    }
    pending = callback;
    releasing = true;
  }

  function resume() {
    releasing = false;
    pending = null;
  }

  Connections {
    target: SessionLock
    function onPreparingForSleepChanged() {
      if (!SessionLock.preparingForSleep)
        root.resume();
    }
  }

  Process {
    id: inhibitor
    running: root.active && !root.releasing
    command: ["systemd-inhibit", "--what=idle:sleep:handle-lid-switch", "--mode=block", "--who=yurice", "--why=Caffeine", "sleep", "infinity"]
    onRunningChanged: {
      if (running || !root.pending)
        return;
      const callback = root.pending;
      root.pending = null;
      callback();
    }
  }

  IpcHandler {
    target: "caffeine"

    function toggle(): void {
      root.toggle();
    }
    function set(on: bool): void {
      root.set(on);
    }
    function get(): bool {
      return root.active;
    }
  }
}
