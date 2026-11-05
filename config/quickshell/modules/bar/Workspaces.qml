import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

Rectangle {
  id: root

  property string output: ""
  property var all: []

  implicitWidth: view.contentWidth + Theme.pillPadding * 2
  implicitHeight: Theme.pillHeight
  radius: height / 2
  color: Theme.surface

  function sync() {
    const target = all.filter(w => root.output === "" || w.output === root.output).sort((a, b) => a.idx - b.idx);
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
      let j = -1;
      for (let k = 0; k < wsModel.count; k++) {
        if (wsModel.get(k).wsId === w.id) {
          j = k;
          break;
        }
      }
      if (j === -1) {
        wsModel.insert(i, item);
      } else {
        if (j !== i)
          wsModel.move(j, i, 1);
        wsModel.set(i, item);
      }
    });
  }

  function handleEvent(event) {
    if (event.WorkspacesChanged) {
      all = event.WorkspacesChanged.workspaces;
    } else if (event.WorkspaceActivated) {
      const {
        id,
        focused
      } = event.WorkspaceActivated;
      const target = all.find(w => w.id === id);
      if (!target)
        return;
      all = all.map(w => Object.assign({}, w, {
          is_active: w.output === target.output ? w.id === id : w.is_active,
          is_focused: focused ? w.id === id : w.is_focused
        }));
    } else if (event.WorkspaceActiveWindowChanged) {
      const {
        workspace_id,
        active_window_id
      } = event.WorkspaceActiveWindowChanged;
      all = all.map(w => w.id === workspace_id ? Object.assign({}, w, {
          active_window_id
        }) : w);
    } else if (event.WorkspaceUrgencyChanged) {
      const {
        id,
        urgent
      } = event.WorkspaceUrgencyChanged;
      all = all.map(w => w.id === id ? Object.assign({}, w, {
          is_urgent: urgent
        }) : w);
    } else {
      return;
    }
    sync();
  }

  onOutputChanged: sync()

  ListModel {
    id: wsModel
  }

  Process {
    command: ["niri", "msg", "--json", "event-stream"]
    running: true
    stdout: SplitParser {
      onRead: line => {
        try {
          root.handleEvent(JSON.parse(line));
        } catch (e) {
          console.warn("Workspaces: bad event line:", line);
        }
      }
    }
  }

  ListView {
    id: view
    anchors.centerIn: parent
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

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(dot.idx)])
      }
    }
  }

  WheelHandler {
    onWheel: event => Quickshell.execDetached(["niri", "msg", "action", event.angleDelta.y > 0 ? "focus-workspace-up" : "focus-workspace-down"])
  }
}
