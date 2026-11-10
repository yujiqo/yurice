import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.services
import qs.modules.bar

PanelWindow {
  id: root

  required property ShellScreen modelData
  readonly property string name: modelData.name
  readonly property bool active: Screenshot.phase !== ""
  readonly property bool selecting: Screenshot.selecting
  readonly property bool primary: Screenshot.output === name
  readonly property bool hasSel: Screenshot.hasSelection && Screenshot.selOutput === name
  readonly property Item view: Screenshot.showPointer ? loader.item?.pointerView ?? null : loader.item?.plainView ?? null

  screen: modelData
  visible: true
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "yurice-screenshot"
  WlrLayershell.keyboardFocus: selecting && primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  color: "transparent"
  mask: Region {
    item: selecting ? content : null
  }

  Component.onCompleted: Screenshot.register(name, root)
  Component.onDestruction: Screenshot.register(name, null)

  onSelectingChanged: {
    if (selecting && primary)
      content.forceActiveFocus();
  }

  function scaleOf(item) {
    return item && item.sourceSize.width > 0 ? item.sourceSize.width / item.width : modelData.devicePixelRatio;
  }

  function grabRegion(callback) {
    const scale = scaleOf(view);
    region.grabToImage(callback, Qt.size(Math.round(region.width * scale), Math.round(region.height * scale)));
  }

  function grabScreen(callback) {
    const target = view;
    const scale = scaleOf(target);
    target.grabToImage(callback, Qt.size(Math.round(target.width * scale), Math.round(target.height * scale)));
  }

  Item {
    id: content
    anchors.fill: parent
    focus: true

    Keys.onPressed: event => {
      const ctrl = event.modifiers & Qt.ControlModifier;
      const shift = event.modifiers & Qt.ShiftModifier;
      if (event.key === Qt.Key_Escape)
        Screenshot.cancel();
      else if (ctrl && shift && event.key === Qt.Key_S)
        Screenshot.saveScreen();
      else if (ctrl && event.key === Qt.Key_S)
        Screenshot.saveRegion();
      else if (ctrl && event.key === Qt.Key_C)
        Screenshot.copy();
      else if (!ctrl && event.key === Qt.Key_P)
        Screenshot.showPointer = !Screenshot.showPointer;
      else
        return;
      event.accepted = true;
    }

    Loader {
      id: loader
      anchors.fill: parent
      active: root.active
      opacity: Screenshot.closing ? 0 : 1

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Easing.OutCubic
        }
      }

      sourceComponent: Item {
        readonly property alias plainView: plain
        readonly property alias pointerView: pointer

        ScreencopyView {
          id: plain
          anchors.fill: parent
          z: Screenshot.showPointer ? 0 : 1
          captureSource: root.modelData
          live: false
          paintCursor: false
          onHasContentChanged: if (hasContent && pointer.hasContent)
            Screenshot.markReady(root.name)
        }

        ScreencopyView {
          id: pointer
          anchors.fill: parent
          z: Screenshot.showPointer ? 1 : 0
          captureSource: root.modelData
          live: false
          paintCursor: true
          onHasContentChanged: if (hasContent && plain.hasContent)
            Screenshot.markReady(root.name)
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      color: "black"
      opacity: root.selecting ? 0.45 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Easing.OutCubic
        }
      }
    }

    Item {
      anchors.fill: parent
      opacity: Screenshot.closing ? 0 : 1

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animHover
          easing.type: Easing.OutCubic
        }
      }

      ShaderEffectSource {
        id: region
        x: Screenshot.selX
        y: Screenshot.selY
        width: Math.max(1, Screenshot.selW)
        height: Math.max(1, Screenshot.selH)
        visible: root.hasSel
        sourceItem: root.view
        sourceRect: Qt.rect(x, y, width, height)
        textureSize: Qt.size(Math.round(width * root.scaleOf(root.view)), Math.round(height * root.scaleOf(root.view)))
        live: true
      }

      Rectangle {
        x: Screenshot.selX - 1
        y: Screenshot.selY - 1
        width: Screenshot.selW + 2
        height: Screenshot.selH + 2
        visible: root.hasSel
        color: "transparent"
        border.width: 2
        border.color: Theme.primary

        Repeater {
          model: [[0, 0], [0.5, 0], [1, 0], [0, 0.5], [1, 0.5], [0, 1], [0.5, 1], [1, 1]]

          Rectangle {
            required property var modelData
            x: parent.width * modelData[0] - width / 2
            y: parent.height * modelData[1] - height / 2
            width: 10
            height: 10
            radius: 5
            color: Theme.primary
            border.width: 2
            border.color: Theme.surface
          }
        }
      }

      Rectangle {
        readonly property bool below: Screenshot.selY + Screenshot.selH + height + 12 < content.height
        visible: root.hasSel
        x: Math.max(4, Math.min(content.width - width - 4, Screenshot.selX + (Screenshot.selW - width) / 2))
        y: below ? Screenshot.selY + Screenshot.selH + 10 : Math.max(4, Screenshot.selY - height - 10)
        width: sizeText.implicitWidth + 16
        height: 24
        radius: 12
        color: Theme.surface

        Text {
          id: sizeText
          anchors.centerIn: parent
          text: Math.round(Screenshot.selW * root.scaleOf(root.view)) + " × " + Math.round(Screenshot.selH * root.scaleOf(root.view))
          color: Theme.text
          font.family: Theme.labelFont
          font.pixelSize: Theme.menuSubtitleSize - 1
        }
      }
    }

    MouseArea {
      id: mouse

      property string mode: ""
      property real pressX: 0
      property real pressY: 0
      property rect start: Qt.rect(0, 0, 0, 0)
      readonly property real grip: 12

      anchors.fill: parent
      enabled: root.selecting
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: shapeFor(hitTest(mouseX, mouseY))

      function hitTest(mx, my) {
        if (!root.hasSel)
          return "";
        const x = Screenshot.selX, y = Screenshot.selY, w = Screenshot.selW, h = Screenshot.selH;
        const inX = mx > x - grip && mx < x + w + grip;
        const inY = my > y - grip && my < y + h + grip;
        let edges = "";
        if (inX && Math.abs(my - y) < grip)
          edges += "t";
        if (inX && Math.abs(my - (y + h)) < grip)
          edges += "b";
        if (inY && Math.abs(mx - x) < grip)
          edges += "l";
        if (inY && Math.abs(mx - (x + w)) < grip)
          edges += "r";
        if (edges !== "")
          return edges;
        return mx > x && mx < x + w && my > y && my < y + h ? "move" : "";
      }

      function shapeFor(hit) {
        switch (hit) {
        case "move":
          return Qt.SizeAllCursor;
        case "t":
        case "b":
          return Qt.SizeVerCursor;
        case "l":
        case "r":
          return Qt.SizeHorCursor;
        case "tl":
        case "br":
          return Qt.SizeFDiagCursor;
        case "tr":
        case "bl":
          return Qt.SizeBDiagCursor;
        default:
          return Qt.CrossCursor;
        }
      }

      function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v));
      }

      onPressed: event => {
        if (event.button === Qt.RightButton) {
          Screenshot.cancel();
          return;
        }
        pressX = clamp(event.x, 0, width);
        pressY = clamp(event.y, 0, height);
        mode = hitTest(event.x, event.y) || "new";
        start = Qt.rect(Screenshot.selX, Screenshot.selY, Screenshot.selW, Screenshot.selH);
        if (mode === "new")
          Screenshot.setSelection(root.name, pressX, pressY, 0, 0);
      }

      onPositionChanged: event => {
        if (!pressed || mode === "")
          return;
        const mx = clamp(event.x, 0, width);
        const my = clamp(event.y, 0, height);
        const dx = mx - pressX;
        const dy = my - pressY;
        if (mode === "new") {
          Screenshot.setSelection(root.name, Math.min(pressX, mx), Math.min(pressY, my), Math.abs(mx - pressX), Math.abs(my - pressY));
        } else if (mode === "move") {
          Screenshot.setSelection(root.name, clamp(start.x + dx, 0, width - start.width), clamp(start.y + dy, 0, height - start.height), start.width, start.height);
        } else {
          let left = start.x, right = start.x + start.width, top = start.y, bottom = start.y + start.height;
          if (mode.includes("l"))
            left += dx;
          if (mode.includes("r"))
            right += dx;
          if (mode.includes("t"))
            top += dy;
          if (mode.includes("b"))
            bottom += dy;
          left = clamp(left, 0, width);
          right = clamp(right, 0, width);
          top = clamp(top, 0, height);
          bottom = clamp(bottom, 0, height);
          Screenshot.setSelection(root.name, Math.min(left, right), Math.min(top, bottom), Math.abs(right - left), Math.abs(bottom - top));
        }
      }

      onReleased: {
        if (mode !== "" && !Screenshot.hasSelection)
          Screenshot.clearSelection();
        mode = "";
      }
    }

    Item {
      anchors.fill: parent
      visible: root.primary && (root.selecting || Screenshot.closing)

      MouseArea {
        x: hint.x
        y: hint.y
        width: hint.width
        height: hint.height
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
      }

      Workspaces {
        id: hint
        output: root.name
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Theme.barMarginTop
        current: root.selecting ? "screenshot" : ""
        onDismissed: Screenshot.cancel()
        onProgressChanged: if (Screenshot.closing && progress < 0.01)
          Screenshot.closed()
      }
    }
  }
}
