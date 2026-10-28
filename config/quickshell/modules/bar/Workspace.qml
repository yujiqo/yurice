import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

Row {
  id: root
  property string output: ""
  property var workspaces: []
  spacing: Theme.s1

  Process {
    id: query
    command: ["niri", "msg", "--json", "workspaces"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const all = JSON.parse(text)
        root.workspaces = all
            .filter(w => w.output === root.output)
            .sort((a, b) => a.idx - b.idx)
      }
    }
  }

  Process {
    command: ["niri", "msg", "--json", "event-stream"]
    running: true
    stdout: SplitParser {
      onRead: query.running = true
    }
  }

  Repeater {
    model: root.workspaces

    Rectangle {
      required property var modelData
      width: modelData.is_active ? Theme.s5 : Theme.s4
      height: Theme.s4
      radius: Theme.rNormal
      color: modelData.is_active ? Theme.accent : Theme.surface

      MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(
          ["niri", "msg", "action", "focus-workspace", String(parent.modelData.idx)]
        )
      }
    }
  }
}
