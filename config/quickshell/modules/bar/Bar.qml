pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.components
import qs.services

PanelWindow {
  id: root

  required property ShellScreen modelData
  property string dropdown: ""
  readonly property bool launcherHere: Launcher.isOpen && Launcher.output === modelData.name
  readonly property bool launcherShown: isLauncher(dropdown)
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
    target: root.covered ? 1 : 0
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
      root.syncLauncher();
    }
  }

  Connections {
    target: Islands
    function onHiddenChanged() {
      if (!Islands.panelShown(root.dropdown))
        root.dropdown = "";
    }
  }

  Connections {
    target: Displays
    function onConfirmingChanged() {
      if (Displays.confirming && root.dropdown === "user")
        root.dropdown = "";
    }
  }

  screen: modelData
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
      y: root.hideOffset
    }
    output: root.modelData.name
    host: root
  }

  Toasts {
    id: toasts
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: workspaces.bottom
    anchors.topMargin: Theme.barGap * 2
    visible: root.modelData.name === Niri.activeOutput
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
      y: root.hideOffset
    }

    UserIsland {
      host: root
    }
    BarSlot {
      shown: !Islands.hidden.includes("media")
      animate: Islands.ready

      MediaIsland {
        host: root
      }
    }
    BarSlot {
      shown: !Islands.hidden.includes("theme")
      animate: Islands.ready

      ThemeIsland {
        host: root
      }
    }
    BarSlot {
      shown: !Islands.hidden.includes("wallpapers")
      animate: Islands.ready

      WallpaperIsland {
        host: root
      }
    }
    BarSlot {
      shown: !Islands.hidden.includes("danbooru")
      animate: Islands.ready

      DanbooruIsland {
        host: root
      }
    }
    BarSlot {
      shown: !Islands.hidden.includes("weeb")
      animate: Islands.ready

      WeebIsland {
        host: root
      }
    }
    BarSlot {
      shown: !Islands.hidden.includes("weather")
      animate: Islands.ready

      WeatherIsland {
        host: root
      }
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
      y: root.hideOffset
    }

    BarSlot {
      shown: !Islands.hidden.includes("connectivity")
      animate: Islands.ready

      ConnectivityIsland {
        host: root
      }
    }
    BarSlot {
      shown: !Islands.hidden.includes("levels")
      animate: Islands.ready

      LevelsIsland {
        host: root
      }
    }
    BarSlot {
      shown: !Islands.hidden.includes("battery")
      animate: Islands.ready

      BatteryIsland {
        host: root
      }
    }
    BarSlot {
      shown: !Islands.hidden.includes("time")
      animate: Islands.ready

      TimeIsland {
        host: root
      }
    }
  }
}
