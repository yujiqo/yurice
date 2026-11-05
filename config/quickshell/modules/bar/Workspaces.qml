import QtQuick
import qs.theme
import qs.services

Rectangle {
  id: root

  property string output: ""

  implicitWidth: view.contentWidth + Theme.pillPadding * 2
  implicitHeight: Theme.pillHeight
  radius: height / 2
  color: Theme.surface

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
        onClicked: Niri.focusWorkspace(dot.idx)
      }
    }
  }

  WheelHandler {
    onWheel: event => Niri.focusWorkspaceRelative(event.angleDelta.y > 0)
  }
}
