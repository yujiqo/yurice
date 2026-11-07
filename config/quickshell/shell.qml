import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.services
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

      readonly property bool launcherHere: Launcher.isOpen && Launcher.output === modelData.name
      readonly property bool launcherShown: dropdown === "launcher" || dropdown === "clipboard"

      function request(name) {
        dropdown = dropdown === name ? "" : name;
      }

      function isLauncher(name) {
        return name === "launcher" || name === "clipboard";
      }

      function syncLauncher() {
        if (Launcher.isOpen && Launcher.output === modelData.name)
          dropdown = Launcher.mode;
        else if (isLauncher(dropdown))
          dropdown = "";
      }

      onLauncherHereChanged: syncLauncher()

      onDropdownChanged: {
        if (Launcher.isOpen && Launcher.output === modelData.name && !isLauncher(dropdown))
          Launcher.close();
      }

      Connections {
        target: Launcher
        function onModeChanged() {
          bar.syncLauncher();
        }
      }

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: Theme.barHeight + Theme.dropdownMaxHeight
      exclusionMode: ExclusionMode.Normal
      exclusiveZone: Theme.barHeight
      WlrLayershell.keyboardFocus: launcherShown ? WlrKeyboardFocus.Exclusive : dropdown !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
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
        current: bar.dropdown
        onDismissed: bar.dropdown = ""
      }

      Row {
        id: leftRow
        anchors.right: workspaces.left
        anchors.rightMargin: Theme.barGap
        anchors.top: parent.top
        spacing: Theme.barGap
        layoutDirection: Qt.RightToLeft

        WeatherIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
        WallpaperSearchIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
        MediaIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
      }

      Row {
        id: rightRow
        anchors.left: workspaces.right
        anchors.leftMargin: Theme.barGap
        anchors.top: parent.top
        spacing: Theme.barGap

        TimeIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
        ConnectivityIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
        LevelsIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
        BatteryIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
      }
    }
  }
}
