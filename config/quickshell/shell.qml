import Quickshell
import QtQuick
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

      Workspaces {
        id: workspaces
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        output: bar.modelData.name
      }

      Row {
        anchors.right: workspaces.left
        anchors.rightMargin: Theme.barGap
        anchors.top: parent.top
        spacing: Theme.barGap
        layoutDirection: Qt.RightToLeft

        MediaIsland {}
      }

      Row {
        anchors.left: workspaces.right
        anchors.leftMargin: Theme.barGap
        anchors.top: parent.top
        spacing: Theme.barGap

        TimeIsland {}
        ConnectivityIsland {}
        LevelsIsland {}
        BatteryIsland {}
      }
    }
  }
}
