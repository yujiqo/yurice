import Quickshell
import Quickshell.Io
import QtQuick

Rectangle {
  id: root

  property string output: ""
  property var all: []

  implicitWidth: view.contentWidth + 20
  implicitHeight: 30
  radius: height / 2
  color: "#040e0d"

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
    height: 12
    orientation: ListView.Horizontal
    interactive: false
    spacing: 6
    model: wsModel

    add: Transition {
      NumberAnimation {
        properties: "opacity,scale"
        from: 0
        to: 1
        duration: 250
        easing.type: Easing.OutBack
      }
    }
    remove: Transition {
      NumberAnimation {
        properties: "opacity,scale"
        to: 0
        duration: 200
        easing.type: Easing.InCubic
      }
    }
    displaced: Transition {
      NumberAnimation {
        properties: "x"
        duration: 250
        easing.type: Easing.OutCubic
      }
    }
    move: Transition {
      NumberAnimation {
        properties: "x"
        duration: 250
        easing.type: Easing.OutCubic
      }
    }

    delegate: Rectangle {
      id: dot
      required property int idx
      required property bool active
      required property bool urgent
      required property bool occupied

      width: active ? 28 : 12
      height: 12
      radius: height / 2
      color: urgent ? "#ff9e64" : active ? "#ff6b6b" : occupied ? "#8a7d6b" : "#2a3634"

      Behavior on width {
        NumberAnimation {
          duration: 250
          easing.type: Easing.OutCubic
        }
      }
      Behavior on color {
        ColorAnimation {
          duration: 200
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
