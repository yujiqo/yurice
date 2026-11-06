import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.modules.bar
import qs.modules.wallpaper

ShellRoot {
  Variants {
    model: Quickshell.screens

    Wallpaper {}
  }

  WallpaperPicker {}

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar

      required property ShellScreen modelData
      screen: modelData

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
        output: bar.modelData.name
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
  }
}
