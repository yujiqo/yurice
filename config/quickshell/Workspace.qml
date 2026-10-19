import QtQuick
import Quickshell
import Quickshell.Io

Row {
  id: root
  property string output: ""
  property var workspaces: []
  spacing: 4

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
      width: modelData.is_active ? 32 : 22
      height: 22
      radius: 11
      color: modelData.is_active ? "#ff6b6b" : "#313244"

      MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(
          ["niri", "msg", "action", "focus-workspace", String(parent.modelData.idx)]
        )
      }
    }
  }
}
