import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.modules.bar

PanelWindow {
  id: bar

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: Theme.barHeight
  margins.top: Theme.barMarginTop
  color: "transparent"

  RowLayout {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Theme.barMargin
    spacing: Theme.barGap

    ClockPill {}
    MediaPill {}
  }

  Workspaces {
    anchors.centerIn: parent
    output: bar.screen?.name ?? ""
  }

  RowLayout {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: Theme.barMargin
    spacing: Theme.barGap

    NetworkPill {}
    BluetoothPill {}
    BrightnessPill {}
    VolumePill {}
    BatteryPill {}
  }
}
