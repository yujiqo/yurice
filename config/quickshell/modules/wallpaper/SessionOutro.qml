import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

Variants {
  model: Session.loggingOut ? Quickshell.screens : []

  PanelWindow {
    required property ShellScreen modelData
    screen: modelData

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "yurice-session-outro"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    Rectangle {
      anchors.fill: parent
      color: "black"
      opacity: Session.outro
    }
  }
}
