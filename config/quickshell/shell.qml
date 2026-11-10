import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.components
import qs.services
import qs.modules.bar
import qs.modules.wallpaper
import qs.modules.lock
import qs.modules.screenshot

ShellRoot {
  settings.watchFiles: !SessionLock.sessionLocked

  Component.onCompleted: {
    Keyboard.watch();
    WallpaperPublish.schedule();
  }

  Variants {
    model: Quickshell.screens

    Wallpaper {}
  }

  WallpaperPicker {}

  LockScreen {}

  SessionIntro {}

  SessionOutro {}

  Variants {
    model: Quickshell.screens

    ScreenshotOverlay {}
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar

      required property ShellScreen modelData
      screen: modelData
      property string dropdown: ""

      readonly property bool launcherHere: Launcher.isOpen && Launcher.output === modelData.name
      readonly property bool launcherShown: dropdown === "launcher" || dropdown === "clipboard"
      readonly property bool powerHere: Session.isOpen && Session.output === modelData.name
      readonly property string keyboardPanel: Panels.output === modelData.name ? Panels.name : ""

      readonly property bool covered: Niri.outputCovered(modelData.name, modelData.width, modelData.height)
      readonly property real hideOffset: -(Theme.barMarginTop + Theme.barHeight + 8) * hide.value

      onCoveredChanged: {
        if (covered)
          dropdown = "";
      }

      Spring {
        id: hide
        target: bar.covered ? 1 : 0
      }

      onKeyboardPanelChanged: {
        if (keyboardPanel !== "")
          dropdown = keyboardPanel;
        else if (Panels.names.includes(dropdown))
          dropdown = "";
      }

      onPowerHereChanged: {
        if (powerHere)
          dropdown = "power";
        else if (dropdown === "power")
          dropdown = "";
      }

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
        if (powerHere && dropdown !== "power")
          Session.close();
        if (keyboardPanel !== "" && dropdown !== keyboardPanel)
          Panels.close();
      }

      Connections {
        target: Launcher
        function onModeChanged() {
          bar.syncLauncher();
        }
      }

      Connections {
        target: WeebMode
        function onHidesDanbooruChanged() {
          if (WeebMode.hidesDanbooru && bar.dropdown === "danbooru")
            bar.dropdown = "";
        }
      }

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: Math.min(Theme.barMarginTop + Theme.barHeight + Theme.dropdownMaxHeight + Theme.toastAreaHeight, modelData.height)
      exclusionMode: ExclusionMode.Normal
      exclusiveZone: Theme.barMarginTop + Theme.barHeight
      WlrLayershell.keyboardFocus: launcherShown || dropdown === "power" || keyboardPanel !== "" ? WlrKeyboardFocus.Exclusive : dropdown !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
      color: "transparent"

      mask: Region {
        item: workspaces

        Region {
          item: leftRow
        }
        Region {
          item: rightRow
        }
        Region {
          x: toasts.x
          y: toasts.y
          width: toasts.visible ? toasts.width : 0
          height: toasts.contentHeight
        }
      }

      Workspaces {
        id: workspaces
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Theme.barMarginTop
        opacity: 1 - hide.value
        transform: Translate {
          y: bar.hideOffset
        }
        output: bar.modelData.name
        current: bar.dropdown
        onDismissed: bar.dropdown = ""
      }

      Toasts {
        id: toasts
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: workspaces.bottom
        anchors.topMargin: Theme.barGap * 2
        visible: bar.modelData.name === (Niri.focusedOutput || Quickshell.screens[0]?.name)
      }

      Row {
        id: leftRow
        anchors.left: parent.left
        anchors.leftMargin: Theme.barMargin
        anchors.top: parent.top
        anchors.topMargin: Theme.barMarginTop
        spacing: Theme.barGap
        opacity: 1 - hide.value
        transform: Translate {
          y: bar.hideOffset
        }

        UserIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
        MediaIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
        ThemeIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
        WallpaperIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
        BarSlot {
          shown: !WeebMode.hidesDanbooru
          animate: WeebMode.loaded

          DanbooruIsland {
            current: bar.dropdown
            onRequest: name => bar.request(name)
            onDismissed: bar.dropdown = ""
          }
        }
        WeebIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
        WeatherIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
      }

      Row {
        id: rightRow
        anchors.right: parent.right
        anchors.rightMargin: Theme.barMargin
        anchors.top: parent.top
        anchors.topMargin: Theme.barMarginTop
        spacing: Theme.barGap
        opacity: 1 - hide.value
        transform: Translate {
          y: bar.hideOffset
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
        TimeIsland {
          current: bar.dropdown
          onRequest: name => bar.request(name)
          onDismissed: bar.dropdown = ""
        }
      }
    }
  }
}
