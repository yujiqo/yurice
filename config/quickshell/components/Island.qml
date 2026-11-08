import QtQuick
import qs.theme
import qs.services

Rectangle {
  id: root

  function navTargets(node, found) {
    for (const child of node.children) {
      if (!child.visible || !child.enabled || child.opacity <= 0)
        continue;
      if (child.activeFocusOnTab)
        found.push(child);
      navTargets(child, found);
    }
    return found;
  }

  function focusedItem() {
    const item = panelArea.Window.activeFocusItem;
    for (let p = item; p; p = p.parent) {
      if (p === panelLoader)
        return item;
    }
    return null;
  }

  function centerOf(item) {
    return item.mapToItem(panelArea, item.width / 2, item.height / 2);
  }

  function scrollerOf(item) {
    for (let p = item.parent; p && p !== panelArea; p = p.parent) {
      if (p.contentItem !== undefined && p.contentY !== undefined)
        return p;
    }
    return null;
  }

  function reveal(item) {
    const scroller = scrollerOf(item);
    if (!scroller)
      return;
    const top = item.mapToItem(scroller.contentItem, 0, 0).y;
    if (top < scroller.contentY)
      scroller.contentY = top;
    else if (top + item.height > scroller.contentY + scroller.height)
      scroller.contentY = top + item.height - scroller.height;
  }

  function focusOn(item) {
    item.forceActiveFocus();
    reveal(item);
  }

  function moveFocus(dx, dy, canScroll) {
    const targets = navTargets(panelLoader, []);
    const from = focusedItem();
    if (!from || !from.activeFocusOnTab && !(from instanceof TextInput)) {
      if (targets.length > 0)
        focusOn(targets[0]);
      return targets.length > 0;
    }
    const origin = centerOf(from);
    let best = null;
    let bestScore = Infinity;
    for (const target of targets) {
      if (target === from)
        continue;
      const center = centerOf(target);
      const along = (center.x - origin.x) * dx + (center.y - origin.y) * dy;
      if (along < 2)
        continue;
      const across = Math.abs((center.x - origin.x) * dy) + Math.abs((center.y - origin.y) * dx);
      const score = along + across * 3;
      if (score < bestScore) {
        best = target;
        bestScore = score;
      }
    }
    if (best) {
      focusOn(best);
      return true;
    }
    const scroller = scrollerOf(from);
    if (scroller && dy !== 0 && canScroll) {
      scroller.contentY = Math.max(0, Math.min(scroller.contentHeight - scroller.height, scroller.contentY + dy * from.height));
      Qt.callLater(moveFocus, dx, dy, false);
    }
    return false;
  }

  function cycleFocus(delta) {
    const targets = navTargets(panelLoader, []);
    if (targets.length === 0)
      return false;
    const index = targets.indexOf(focusedItem());
    focusOn(targets[index < 0 ? 0 : (index + delta + targets.length) % targets.length]);
    return true;
  }

  function activateFocused() {
    const item = focusedItem();
    if (!item || !item.activeFocusOnTab)
      return false;
    if (item.keyActivate)
      item.keyActivate();
    else if (item.clicked)
      item.clicked();
    else
      return false;
    return true;
  }

  function handleNavKey(event) {
    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
      return false;
    let dx = 0;
    let dy = 0;
    switch (event.key) {
    case Qt.Key_H:
    case Qt.Key_Left:
      dx = -1;
      break;
    case Qt.Key_L:
    case Qt.Key_Right:
      dx = 1;
      break;
    case Qt.Key_K:
    case Qt.Key_Up:
      dy = -1;
      break;
    case Qt.Key_J:
    case Qt.Key_Down:
      dy = 1;
      break;
    case Qt.Key_Tab:
      return cycleFocus(1);
    case Qt.Key_Backtab:
      return cycleFocus(-1);
    case Qt.Key_Return:
    case Qt.Key_Enter:
    case Qt.Key_Space:
      return activateFocused();
    default:
      return false;
    }
    const item = focusedItem();
    if (dx !== 0 && item?.keyAdjust) {
      item.keyAdjust(dx);
      return true;
    }
    moveFocus(dx, dy, true);
    return true;
  }

  function focusFirstForKeyboard() {
    if (!Panels.keyboard || !open)
      return;
    const item = focusedItem();
    if (item && (item.activeFocusOnTab || item instanceof TextInput))
      return;
    const targets = navTargets(panelLoader, []);
    if (targets.length > 0)
      focusOn(targets[0]);
  }

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
  readonly property bool holding: hold || (panelLoader.item?.keepOpen ?? false) || (open && Panels.keyboard)

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
    Keys.onPressed: event => event.accepted = root.handleNavKey(event)
    Keys.onEscapePressed: root.dismissed()

    Loader {
      id: panelLoader
      width: parent.width
      active: root.open || openSpring.value > 0.01
      sourceComponent: root.shownPanel
      focus: true
      onLoaded: Qt.callLater(root.focusFirstForKeyboard)
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
