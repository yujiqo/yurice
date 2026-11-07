import Quickshell
import Quickshell.Wayland
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
      property string dropdown: ""

      function request(name) {
        dropdown = dropdown === name ? "" : name;
      }

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: Theme.barHeight + Theme.dropdownMaxHeight
      exclusionMode: ExclusionMode.Normal
      exclusiveZone: Theme.barHeight
      WlrLayershell.keyboardFocus: dropdown !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
      margins.top: Theme.barMarginTop
      color: "transparent"

      mask: Region {
        item: workspaces

        Region {
          item: leftRow
        }
        Region {
          item: rightRow
        }
      }

      Workspaces {
        id: workspaces
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        output: bar.modelData.name
      }

      Row {
        id: leftRow
        anchors.right: workspaces.left
        anchors.rightMargin: Theme.barGap
        anchors.top: parent.top
        spacing: Theme.barGap
        layoutDirection: Qt.RightToLeft

        MediaIsland {}
      }

      Row {
        id: rightRow
        anchors.left: workspaces.right
        anchors.leftMargin: Theme.barGap
        anchors.top: parent.top
        spacing: Theme.barGap

        TimeIsland {}
        ConnectivityIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
        LevelsIsland {}
        BatteryIsland {}
      }
    }
  }
}
