import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  property string osd: ""
  property bool ready: false
  readonly property string shown: current === "brightness" || current === "volume" ? current : osd

  readonly property var volumeSegment: {
    const percent = Audio.percent;
    if (Audio.wiredHeadphones)
      return Audio.muted ? Utility.seg("headset_off", "Muted", Theme.off) : Utility.seg("headphones", percent + "%", Theme.volume);
    if (Audio.muted || percent === 0)
      return Utility.seg("volume_off", Audio.muted ? "Muted" : "0%", Theme.off);
    return Utility.seg(Utility.pick(percent, [[66, "volume_up"], [33, "volume_down"]], "volume_mute"), percent + "%", Theme.volume);
  }

  function flash(kind) {
    if (!ready || current === kind)
      return;
    osd = kind;
    osdTimer.restart();
  }

  open: shown !== ""
  hold: osd !== ""
  panelWidth: 280
  panel: shown === "brightness" ? brightnessPanel : shown === "volume" ? volumePanel : null
  panelIndex: shown === "volume" ? 1 : 0

  onHoveredChanged: {
    if (hovered && osd !== "") {
      if (current !== osd)
        request(osd);
      osd = "";
    }
  }

  Connections {
    target: root
    function onDismissed() {
      root.osd = "";
    }
  }

  Connections {
    target: Brightness
    function onPercentChanged() {
      root.flash("brightness");
    }
  }

  Connections {
    target: Audio
    function onPercentChanged() {
      root.flash("volume");
    }
    function onMutedChanged() {
      root.flash("volume");
    }
  }

  Timer {
    interval: 1000
    running: true
    onTriggered: root.ready = true
  }

  Timer {
    id: osdTimer
    interval: 1500
    onTriggered: root.osd = ""
  }

  Component {
    id: brightnessPanel

    LevelsPanel {
      kind: "brightness"
    }
  }

  Component {
    id: volumePanel

    LevelsPanel {
      kind: "volume"
    }
  }

  Segment {
    visible: Brightness.available
    icon: Utility.pick(Brightness.percent, [[66, "brightness_high"], [33, "brightness_medium"]], "brightness_low")
    label: Brightness.percent + "%"
    color: Theme.brightness
    showLabel: root.expanded
    clickable: true
    onClicked: root.request("brightness")
    onPressedChanged: root.held = pressed
    onWheel: event => Brightness.step(event.angleDelta.y > 0)
  }

  Segment {
    icon: root.volumeSegment.icon
    label: root.volumeSegment.label
    color: root.volumeSegment.color
    showLabel: root.expanded
    clickable: true
    onClicked: mouse => mouse.button === Qt.RightButton ? Audio.toggleMute() : root.request("volume")
    onPressedChanged: root.held = pressed
    onWheel: event => Audio.changeVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
  }
}
