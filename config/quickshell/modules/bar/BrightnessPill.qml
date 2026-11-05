import QtQuick
import Quickshell.Io
import qs.theme
import qs.components

Pill {
  id: root

  readonly property string backlightDir: "/sys/class/backlight/intel_backlight"
  readonly property bool hasBacklight: brightnessMax.loaded && brightnessCur.loaded
  readonly property int percent: Math.round(parseInt(brightnessCur.text()) / parseInt(brightnessMax.text()) * 100) || 0

  visible: hasBacklight
  segments: [Utility.seg(Utility.pick(percent, [[66, "brightness_high"], [33, "brightness_medium"]], "brightness_low"), percent + "%", Theme.brightness)]

  FileView {
    id: brightnessMax
    path: root.backlightDir + "/max_brightness"
  }

  FileView {
    id: brightnessCur
    path: root.backlightDir + "/actual_brightness"
    watchChanges: true
    onFileChanged: reload()
  }

  Process {
    id: brightnessWrite
  }

  WheelHandler {
    onWheel: event => {
      if (brightnessWrite.running)
        return;
      const step = event.angleDelta.y > 0 ? "5%+" : "5%-";
      brightnessWrite.command = ["brightnessctl", "-c", "backlight", "-n", "1%", "-q", "s", step];
      brightnessWrite.running = true;
    }
  }
}
