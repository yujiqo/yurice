// DemoPanels.qml — temporary M2 scaffold proving PopupPanel works on every edge value.
// Delete this file (and its "demo*" IPC targets) once M3 adds the real center panel.
import QtQuick
import Quickshell
import qs.theme
import qs.components

Scope {
  PopupPanel {
    edge: "center"
    ipcTarget: "demoCenter"
    content: Component { Pill { text: "edge: center" } }
  }
  PopupPanel {
    edge: "left"
    ipcTarget: "demoLeft"
    content: Component { Pill { text: "edge: left" } }
  }
  PopupPanel {
    edge: "top"
    ipcTarget: "demoTop"
    content: Component { Pill { text: "edge: top" } }
  }
  PopupPanel {
    edge: "right"
    ipcTarget: "demoRight"
    content: Component { Pill { text: "edge: right" } }
  }
  PopupPanel {
    edge: "bottom"
    ipcTarget: "demoBottom"
    content: Component { Pill { text: "edge: bottom" } }
  }
}
