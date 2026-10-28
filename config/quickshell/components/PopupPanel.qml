// PopupPanel.qml — shared edge-sliding popup used by every panel (center/left/top/right/bottom).
// Owns its own IPC target, so every future panel gets `qs ipc call <target> toggle/open/close`
// for free instead of each module wiring an IpcHandler by hand (see docs/DESIGN.md "Panels").
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.theme

// Scope: a non-visual container, since this component's job is to own windows/IPC, not render.
Scope {
  id: root

  // Which screen edge this panel slides from. "center" fades + scales instead of sliding.
  property string edge: "center" // "left" | "top" | "right" | "bottom" | "center"
  // Unique `qs ipc call <ipcTarget> ...` name — required, every popup must be IPC-toggleable.
  required property string ipcTarget
  // Panel body, set by the consumer: `content: Component { Pill { text: "hi" } }`.
  property Component content

  property bool panelVisible: false
  // Stays true a little past panelVisible=false, so PanelWindow.visible (which has no
  // animation of its own) doesn't cut the close animation off mid-flight.
  property bool shown: false

  function open() { panelVisible = true }
  function close() { panelVisible = false }
  function toggle() { panelVisible = !panelVisible }

  onPanelVisibleChanged: {
    if (panelVisible) { closeTimer.stop(); shown = true }
    else closeTimer.restart()
  }
  Timer { id: closeTimer; interval: Theme.animNormal; onTriggered: root.shown = false }

  IpcHandler {
    target: root.ipcTarget
    function toggle(): void { root.toggle() }
    function open(): void { root.open() }
    function close(): void { root.close() }
  }

  PanelWindow {
    id: win
    screen: Quickshell.screens[0]
    visible: root.shown
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    WlrLayershell.layer: WlrLayer.Overlay
    // OnDemand only while open, so the panel doesn't hold keyboard focus once closed.
    WlrLayershell.keyboardFocus: root.panelVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Click anywhere outside the content area closes the panel.
    MouseArea {
      anchors.fill: parent
      onClicked: mouse => {
        const p = mapToItem(contentBox, mouse.x, mouse.y)
        if (p.x < 0 || p.x > contentBox.width || p.y < 0 || p.y > contentBox.height)
          root.close()
      }

      Item {
        id: contentBox
        width: loader.implicitWidth
        height: loader.implicitHeight
        opacity: root.panelVisible ? 1 : 0
        scale: root.edge === "center" ? (root.panelVisible ? 1 : 0.94) : 1

        focus: root.panelVisible
        Keys.onPressed: event => {
          if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
          }
        }

        Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeOut } }
        Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeOut } }
        Behavior on _hiddenAmount { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeOut } }

        anchors {
          horizontalCenter: (root.edge === "center" || root.edge === "top" || root.edge === "bottom") ? parent.horizontalCenter : undefined
          verticalCenter: (root.edge === "center" || root.edge === "left" || root.edge === "right") ? parent.verticalCenter : undefined
          left: root.edge === "left" ? parent.left : undefined
          right: root.edge === "right" ? parent.right : undefined
          top: root.edge === "top" ? parent.top : undefined
          bottom: root.edge === "bottom" ? parent.bottom : undefined
          margins: Theme.s5
        }

        // Distance still slid off-screen; animates to 0 on open, back out on close.
        readonly property bool horizontalEdge: root.edge === "left" || root.edge === "right"
        property real _hiddenAmount: root.panelVisible ? 0 : ((horizontalEdge ? width : height) + Theme.s5)

        transform: Translate {
          x: contentBox.horizontalEdge ? (root.edge === "left" ? -contentBox._hiddenAmount : contentBox._hiddenAmount) : 0
          y: (!contentBox.horizontalEdge && root.edge !== "center") ? (root.edge === "top" ? -contentBox._hiddenAmount : contentBox._hiddenAmount) : 0
        }

        Loader {
          id: loader
          sourceComponent: root.content
        }
      }
    }
  }
}
