import QtQuick
import qs.theme

Rectangle {
  id: root

  default property alias content: row.data
  readonly property bool hovered: hover.hovered
  readonly property bool expanded: hovered || open
  property real padding: Theme.pillPadding
  property real spacing: Theme.pillSegmentGap
  property bool clickable: false

  property string current: ""
  property bool open: false
  property Component panel: null
  property Component shownPanel: null
  readonly property real progress: Math.max(0, Math.min(1, openSpring.value))
  readonly property bool holding: panelLoader.item?.keepOpen ?? false

  signal clicked(var mouse)
  signal request(string name)
  signal dismissed

  readonly property real compactWidth: row.implicitWidth + padding * 2
  readonly property real openWidth: Math.max(compactWidth, Theme.panelWidth)

  implicitWidth: compactWidth + (openWidth - compactWidth) * openSpring.value
  implicitHeight: Theme.pillHeight + panelHeight.value * openSpring.value
  radius: Theme.pillHeight / 2 + (Theme.panelRadius - Theme.pillHeight / 2) * progress
  color: Theme.surface
  clip: true
  scale: mouse.pressed ? 0.95 : 1

  onPanelChanged: {
    if (panel)
      shownPanel = panel;
  }

  onOpenChanged: {
    if (open)
      panelArea.forceActiveFocus();
  }

  Behavior on scale {
    NumberAnimation {
      duration: Theme.animPress
    }
  }

  Spring {
    id: openSpring
    target: root.open && root.shownPanel ? 1 : 0
  }

  Spring {
    id: panelHeight
    target: panelLoader.item ? panelLoader.item.implicitHeight + Theme.panelPadding : 0
    onTargetChanged: {
      if (openSpring.value < 0.01) {
        velocity = 0;
        value = target;
      }
    }
  }

  MouseArea {
    id: mouse
    width: parent.width
    height: Theme.pillHeight
    enabled: root.clickable
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: event => root.clicked(event)
  }

  Row {
    id: row
    x: root.padding
    height: Theme.pillHeight
    spacing: root.spacing
  }

  Item {
    id: panelArea
    x: Theme.panelPadding
    y: Theme.pillHeight
    width: root.openWidth - Theme.panelPadding * 2
    height: panelLoader.height
    opacity: Math.max(0, root.progress * 2 - 1)
    focus: true
    Keys.onEscapePressed: root.dismissed()

    Loader {
      id: panelLoader
      width: parent.width
      active: root.open || openSpring.value > 0.01
      sourceComponent: root.shownPanel
      focus: true
    }
  }

  HoverHandler {
    id: hover
  }

  Timer {
    interval: Theme.closeGrace
    running: root.open && !root.hovered && !root.holding
    onTriggered: root.dismissed()
  }
}
