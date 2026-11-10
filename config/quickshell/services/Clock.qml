pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.theme

Singleton {
  id: root

  readonly property alias date: clock.date
  property string timeFormat: ""
  property string shortTimeFormat: ""
  property bool clock24h: true
  property real fade: 1

  function applyFormat() {
    timeFormat = Settings.timeFormat;
    shortTimeFormat = Settings.shortTimeFormat;
    clock24h = Settings.clock24h;
  }

  Connections {
    target: Settings
    function onTimeFormatChanged() {
      formatSwap.restart();
    }
  }

  SequentialAnimation {
    id: formatSwap

    NumberAnimation {
      target: root
      property: "fade"
      to: 0
      duration: Theme.animFadeOut
      easing.type: Easing.InQuad
    }
    ScriptAction {
      script: root.applyFormat()
    }
    NumberAnimation {
      target: root
      property: "fade"
      to: 1
      duration: Theme.animFadeIn
      easing.type: Easing.OutQuad
    }
  }

  Component.onCompleted: applyFormat()

  SystemClock {
    id: clock
    precision: Settings.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
  }
}
