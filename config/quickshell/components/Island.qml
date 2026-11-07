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
  property bool held: false

  property string current: ""
  property bool open: false
  property bool hold: false
  property real panelWidth: Theme.panelWidth
  property Component panel: null
  property Component shownPanel: null
  property Component pendingPanel: null
  property int panelIndex: 0
  property int shownIndex: 0
  property real switchFade: 1
  property real switchSlide: 0
  property int switchDir: 1
  readonly property real progress: Math.max(0, Math.min(1, openSpring.value))
  readonly property bool holding: hold || (panelLoader.item?.keepOpen ?? false)

  signal clicked(var mouse)
  signal request(string name)
  signal dismissed

  readonly property real compactWidth: row.implicitWidth + padding * 2
  readonly property real openWidth: Math.max(compactWidth, panelWidth)

  implicitWidth: compactWidth + (openWidth - compactWidth) * openSpring.value
  implicitHeight: Theme.pillHeight + panelHeight.value * openSpring.value
  radius: Theme.pillHeight / 2 + (Theme.panelRadius - Theme.pillHeight / 2) * progress
  color: Theme.surface
  clip: true
  transformOrigin: Item.Top
  scale: mouse.pressed || held ? (open ? 0.98 : 0.95) : 1

  onPanelChanged: {
    if (!panel)
      return;
    if (shownPanel && shownPanel !== panel && open && progress > 0.5) {
      pendingPanel = panel;
      Qt.callLater(startSwitch);
    } else {
      switchAnim.stop();
      switchFade = 1;
      switchSlide = 0;
      shownPanel = panel;
      shownIndex = panelIndex;
    }
  }

  function startSwitch() {
    switchDir = panelIndex >= shownIndex ? 1 : -1;
    switchAnim.restart();
  }

  SequentialAnimation {
    id: switchAnim

    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "switchFade"
        to: 0
        duration: Theme.animPress
        easing.type: Easing.InQuad
      }
      NumberAnimation {
        target: root
        property: "switchSlide"
        to: -root.switchDir * Theme.slideDistance / 2
        duration: Theme.animPress
        easing.type: Easing.InQuad
      }
    }
    ScriptAction {
      script: {
        root.shownPanel = root.pendingPanel;
        root.shownIndex = root.panelIndex;
        root.switchSlide = root.switchDir * Theme.slideDistance;
      }
    }
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "switchFade"
        to: 1
        duration: Theme.animMove
        easing.type: Easing.OutQuad
      }
      NumberAnimation {
        target: root
        property: "switchSlide"
        to: 0
        duration: Theme.animSlide
        easing.type: Easing.OutCubic
      }
    }
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
    hoverEnabled: root.clickable
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: event => root.clicked(event)
  }

  HoverHighlight {
    x: row.x - root.padding + 3
    y: 3
    width: root.compactWidth - 6
    active: root.clickable && mouse.containsMouse
  }

  Row {
    id: row
    x: (root.width - row.implicitWidth) / 2
    height: Theme.pillHeight
    spacing: root.spacing
  }

  Item {
    id: panelArea
    x: Theme.panelPadding
    y: Theme.pillHeight
    width: root.openWidth - Theme.panelPadding * 2
    height: panelLoader.height
    opacity: Math.max(0, root.progress * 2 - 1) * root.switchFade
    focus: true
    transform: Translate {
      x: root.switchSlide
    }
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
