// DemoPanels.qml — temporary M2 scaffold proving PopupPanel works on every edge value.
// "center" is now the real CenterPanel (M3a); left/top/right/bottom stay demos until their
// milestones (M4-M7) land.
import QtQuick
import Quickshell
import qs.theme
import qs.components

Scope {
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
