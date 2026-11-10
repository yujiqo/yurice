import QtQuick
import qs.theme
import qs.components
import qs.services

Rectangle {
  id: root

  readonly property real padding: 20
  readonly property var rects: Displays.outputs.filter(o => Displays.draft[o.name]?.enabled).map(o => Object.assign({
        name: o.name
      }, Displays.rectOf(Displays.draft, o.name)))
  readonly property var bounds: {
    if (rects.length === 0)
      return {
        x: 0,
        y: 0,
        width: 1,
        height: 1
      };
    const minX = Math.min(...rects.map(r => r.x));
    const minY = Math.min(...rects.map(r => r.y));
    const maxX = Math.max(...rects.map(r => r.x + r.width));
    const maxY = Math.max(...rects.map(r => r.y + r.height));
    return {
      x: minX,
      y: minY,
      width: Math.max(1, maxX - minX),
      height: Math.max(1, maxY - minY)
    };
  }
  property bool dragging: false
  property var frozen: null
  readonly property var view: frozen ?? fit(bounds)

  implicitHeight: 190
  radius: Theme.menuItemRadius
  color: Theme.surfaceContainer

  function fit(b) {
    const scale = Math.min((width - padding * 2) / b.width, (height - padding * 2) / b.height);
    return {
      scale: scale,
      x: (width - b.width * scale) / 2 - b.x * scale,
      y: (height - b.height * scale) / 2 - b.y * scale
    };
  }

  Text {
    anchors.centerIn: parent
    visible: root.rects.length === 0
    text: "No displays enabled"
    color: Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuSubtitleSize
  }

  Repeater {
    model: Displays.outputs

    Rectangle {
      id: tile

      required property var modelData
      readonly property var rect: Displays.draft[modelData.name]?.enabled ? Displays.rectOf(Displays.draft, modelData.name) : ({
          x: 0,
          y: 0,
          width: 0,
          height: 0
        })
      readonly property bool shownOnCanvas: Displays.draft[modelData.name]?.enabled ?? false
      readonly property bool selected: Displays.selected === modelData.name
      readonly property real homeX: root.view.x + rect.x * root.view.scale
      readonly property real homeY: root.view.y + rect.y * root.view.scale

      x: homeX
      y: homeY
      z: drag.pressed ? 2 : selected ? 1 : 0
      width: Math.max(8, rect.width * root.view.scale - 3)
      height: Math.max(8, rect.height * root.view.scale - 3)
      radius: 8
      color: selected ? Theme.primaryContainer : drag.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
      border.width: selected ? 2 : 1
      border.color: selected ? Theme.primary : Theme.divider
      visible: shownOnCanvas
      opacity: Displays.confirming ? 0.6 : 1

      Behavior on x {
        enabled: !drag.pressed
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }

      Behavior on y {
        enabled: !drag.pressed
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }

      Behavior on width {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }

      Behavior on height {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }

      Behavior on color {
        ColorAnimation {
          duration: Theme.animHover
        }
      }

      Column {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 1

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: tile.modelData.name
          elide: Text.ElideRight
          color: tile.selected ? Theme.textOnPrimaryContainer : Theme.text
          font.family: Theme.labelFont
          font.pixelSize: Theme.menuSubtitleSize
          font.bold: true
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          visible: tile.height > 44
          text: `${Displays.draft[tile.modelData.name]?.width ?? 0}×${Displays.draft[tile.modelData.name]?.height ?? 0}`
          elide: Text.ElideRight
          color: tile.selected ? Theme.textOnPrimaryContainer : Theme.textVariant
          font.family: Theme.labelFont
          font.pixelSize: Theme.menuSubtitleSize - 3
        }
      }

      MouseArea {
        id: drag

        property real grabX: 0
        property real grabY: 0
        property bool moved: false

        anchors.fill: parent
        enabled: !Displays.confirming
        hoverEnabled: true
        preventStealing: true
        cursorShape: pressed && moved ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        onPressed: mouse => {
          Displays.selected = tile.modelData.name;
          root.frozen = root.view;
          grabX = mouse.x;
          grabY = mouse.y;
          moved = false;
        }
        onPositionChanged: mouse => {
          if (!pressed)
            return;
          const p = mapToItem(root, mouse.x, mouse.y);
          if (!moved && Math.hypot(mouse.x - grabX, mouse.y - grabY) < 3)
            return;
          moved = true;
          tile.x = Math.max(-tile.width / 2, Math.min(root.width - tile.width / 2, p.x - grabX));
          tile.y = Math.max(-tile.height / 2, Math.min(root.height - tile.height / 2, p.y - grabY));
        }
        onReleased: {
          if (moved) {
            const v = root.view;
            Displays.move(tile.modelData.name, (tile.x - v.x) / v.scale, (tile.y - v.y) / v.scale);
          }
          tile.x = Qt.binding(() => tile.homeX);
          tile.y = Qt.binding(() => tile.homeY);
          root.frozen = null;
        }
        onCanceled: {
          tile.x = Qt.binding(() => tile.homeX);
          tile.y = Qt.binding(() => tile.homeY);
          root.frozen = null;
        }
      }
    }
  }
}
