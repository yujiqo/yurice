import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  property string output: ""
  property Item hoveredDot: null
  property real wheelDelta: 0

  readonly property var panelNames: ["launcher", "clipboard", "power", "hotkeys", "screenshot"]

  open: panelNames.includes(current)
  panel: current === "launcher" ? launcherPanel : current === "clipboard" ? clipboardPanel : current === "power" ? powerPanel : current === "hotkeys" ? hotkeysPanel : current === "screenshot" ? screenshotPanel : null
  panelIndex: Math.max(0, panelNames.indexOf(current))
  panelWidth: shownPanel === screenshotPanel ? 520 : shownPanel === powerPanel || shownPanel === hotkeysPanel ? 440 : Theme.launcherWidth
  Behavior on panelWidth {
    NumberAnimation {
      duration: Theme.animMove
      easing.type: Easing.OutCubic
    }
  }
  hold: true

  Component {
    id: launcherPanel

    LauncherPanel {}
  }

  Component {
    id: clipboardPanel

    ClipboardPanel {}
  }

  Component {
    id: powerPanel

    PowerPanel {}
  }

  Component {
    id: hotkeysPanel

    HotkeysPanel {}
  }

  Component {
    id: screenshotPanel

    ScreenshotPanel {}
  }

  function indexOfWs(wsId) {
    for (let k = 0; k < wsModel.count; k++) {
      if (wsModel.get(k).wsId === wsId)
        return k;
    }
    return -1;
  }

  function sync() {
    const target = Niri.workspaces.filter(w => root.output === "" || w.output === root.output).sort((a, b) => a.idx - b.idx);
    const ids = target.map(w => w.id);

    for (let i = wsModel.count - 1; i >= 0; i--) {
      if (!ids.includes(wsModel.get(i).wsId))
        wsModel.remove(i);
    }

    target.forEach((w, i) => {
      const item = {
        wsId: w.id,
        idx: w.idx,
        active: w.is_active,
        urgent: w.is_urgent,
        occupied: w.active_window_id !== null
      };
      const j = indexOfWs(w.id);
      if (j === -1) {
        wsModel.insert(i, item);
      } else {
        if (j !== i)
          wsModel.move(j, i, 1);
        wsModel.set(i, item);
      }
    });
  }

  onOutputChanged: sync()

  Connections {
    target: Niri
    function onWorkspacesChanged() {
      root.sync();
    }
  }

  Component.onCompleted: sync()

  ListModel {
    id: wsModel
  }

  Item {
    width: view.contentWidth
    height: Theme.pillHeight

    HoverHighlight {
      id: highlight
      y: 3
      active: root.hoveredDot !== null

      Behavior on x {
        enabled: highlight.opacity > 0
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }
      Behavior on width {
        enabled: highlight.opacity > 0
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }
    }

    Binding {
      target: highlight
      property: "x"
      value: view.x + (root.hoveredDot?.x ?? 0) - 7
      when: root.hoveredDot !== null
      restoreMode: Binding.RestoreNone
    }

    Binding {
      target: highlight
      property: "width"
      value: (root.hoveredDot?.width ?? 0) + 14
      when: root.hoveredDot !== null
      restoreMode: Binding.RestoreNone
    }

    ListView {
      id: view
      anchors.verticalCenter: parent.verticalCenter
      width: contentWidth
      height: Theme.wsDot
      orientation: ListView.Horizontal
      interactive: false
      spacing: Theme.wsGap
      model: wsModel

      add: Transition {
        NumberAnimation {
          properties: "opacity,scale"
          from: 0
          to: 1
          duration: Theme.animMove
          easing.type: Easing.OutBack
        }
      }
      remove: Transition {
        NumberAnimation {
          properties: "opacity,scale"
          to: 0
          duration: Theme.animRemove
          easing.type: Easing.InCubic
        }
      }
      displaced: Transition {
        NumberAnimation {
          properties: "x"
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }
      move: Transition {
        NumberAnimation {
          properties: "x"
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }

      delegate: Rectangle {
        id: dot
        required property int idx
        required property bool active
        required property bool urgent
        required property bool occupied

        width: active ? Theme.wsDotActive : Theme.wsDot
        height: Theme.wsDot
        radius: height / 2
        color: urgent ? Theme.wsUrgent : active ? Theme.wsActive : occupied ? Theme.wsOccupied : Theme.wsEmpty

        Behavior on width {
          NumberAnimation {
            duration: Theme.animMove
            easing.type: Theme.easeOut
          }
        }
        Behavior on color {
          ColorAnimation {
            duration: Theme.animColor
          }
        }

        Component.onDestruction: {
          if (root.hoveredDot === dot)
            root.hoveredDot = null;
        }

        MouseArea {
          x: -Theme.wsGap / 2
          y: (parent.height - Theme.pillHeight) / 2
          width: parent.width + Theme.wsGap
          height: Theme.pillHeight
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onContainsMouseChanged: {
            if (containsMouse)
              root.hoveredDot = dot;
            else if (root.hoveredDot === dot)
              root.hoveredDot = null;
          }
          onClicked: Niri.focusWorkspace(root.output, dot.idx)
        }
      }
    }
  }

  WheelHandler {
    enabled: !root.open
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => {
      root.wheelDelta += event.angleDelta.y;
      while (root.wheelDelta >= 120) {
        root.wheelDelta -= 120;
        Niri.focusWorkspaceRelative(root.output, true);
      }
      while (root.wheelDelta <= -120) {
        root.wheelDelta += 120;
        Niri.focusWorkspaceRelative(root.output, false);
      }
    }
  }
}
