import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.theme

Scope {
  id: root

  property string edge: "center" // "left" | "top" | "right" | "bottom" | "center"
  required property string ipcTarget
  property Component content

  property bool panelVisible: false
  property bool shown: false
  property string _focusedScreenName: ""

  function open() {
    if (outputDetector.running) return
    outputDetector.running = true
  }
  function close() { panelVisible = false }
  function toggle() {
    if (panelVisible) close()
    else open()
  }

  Process {
    id: outputDetector
    command: ["niri", "msg", "-j", "focused-output"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const name = JSON.parse(text).name
          if (name) root._focusedScreenName = name
        } catch (e) {}
        root.panelVisible = true
      }
    }
  }

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
    screen: Quickshell.screens.find(s => s.name === root._focusedScreenName) ?? Quickshell.screens[0]
    visible: root.shown
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.panelVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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
