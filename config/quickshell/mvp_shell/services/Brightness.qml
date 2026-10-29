// Brightness.qml — wraps brightnessctl (no Quickshell brightness service exists; verified
// against the locally installed 0.3.0 module list). Debounces writes so dragging/scrolling
// the slider doesn't spam the CLI tool.
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string device: ""
  readonly property bool available: device !== ""
  property real value: 0 // 0..1
  property bool _localWritePending: false // suppresses the poll while we're mid-drag/just wrote

  function setValue(v) {
    value = Math.max(0, Math.min(1, v))
    _localWritePending = true
    settleTimer.restart()
    writeTimer.restart()
  }

  Component.onCompleted: detect.running = true

  // one-shot: find the backlight device and its current percentage
  Process {
    id: detect
    command: ["brightnessctl", "-m", "-c", "backlight"]
    stdout: StdioCollector {
      onStreamFinished: {
        const line = text.trim().split("\n")[0]
        if (!line) return
        const parts = line.split(",")
        if (parts.length < 4) return
        root.device = parts[0]
        const percent = parseInt(parts[3])
        if (!isNaN(percent)) root.value = percent / 100
      }
    }
  }

  Timer {
    id: writeTimer
    interval: 60 // coalesce rapid drag/scroll events into one write
    onTriggered: {
      if (!root.available) return
      write.command = ["brightnessctl", "-d", root.device, "s", Math.round(root.value * 100) + "%", "--quiet"]
      write.running = true
    }
  }
  Process { id: write }

  // nothing else notifies us when brightness changes externally (e.g. the XF86MonBrightness*
  // hardware keys, bound in niri to call brightnessctl directly) — same Timer+Process poll
  // shape as the wifi status Pill in shell.qml, since Quickshell has no push/reactive mechanism
  // for state outside its own services.
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: if (!root._localWritePending) detect.running = true
  }
  Timer {
    id: settleTimer
    interval: 400 // longer than writeTimer's debounce, so a real write lands before we resume polling
    onTriggered: root._localWritePending = false
  }
}
