pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  property real centerX: 0.5
  property real centerY: 0.5
  property real radius: 0.5
  readonly property real minRadius: 0.08

  spacing: 10

  function reset() {
    centerX = 0.5;
    centerY = 0.5;
    radius = 0.5;
  }

  function place(px, py, pr) {
    const w = area.width;
    const h = area.height;
    const shortest = Math.min(w, h);
    if (shortest <= 0)
      return;
    const r = Math.max(minRadius * shortest, Math.min(shortest / 2, pr));
    radius = r / shortest;
    centerX = Math.max(r, Math.min(w - r, px)) / w;
    centerY = Math.max(r, Math.min(h - r, py)) / h;
  }

  function apply() {
    const r = area.r;
    AvatarEditor.save((area.cx - r) / area.width, (area.cy - r) / area.height, 2 * r / area.width);
  }

  Connections {
    target: AvatarEditor
    function onFileChanged() {
      root.reset();
    }
  }

  Item {
    id: viewport
    width: parent.width
    height: 400

    Image {
      id: image
      anchors.fill: parent
      fillMode: Image.PreserveAspectFit
      source: Paths.fileUrl(AvatarEditor.file)
      sourceSize: Qt.size(1600, 1600)
      autoTransform: true
      asynchronous: true
      smooth: true
      mipmap: true
      opacity: status === Image.Ready ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animMove
        }
      }
    }

    Spinner {
      anchors.centerIn: parent
      visible: image.status === Image.Loading
    }

    Text {
      anchors.centerIn: parent
      visible: image.status === Image.Error
      text: "Can't open this image"
      color: Theme.textVariant
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuSubtitleSize
    }

    Item {
      id: area

      readonly property real shortest: Math.min(width, height)
      readonly property real r: root.radius * shortest
      readonly property real cx: root.centerX * width
      readonly property real cy: root.centerY * height
      readonly property real border: Math.max(width, height) * 2

      x: (viewport.width - image.paintedWidth) / 2
      y: (viewport.height - image.paintedHeight) / 2
      width: image.paintedWidth
      height: image.paintedHeight
      visible: image.status === Image.Ready
      opacity: image.opacity
      clip: true

      Rectangle {
        x: area.cx - area.r - area.border
        y: area.cy - area.r - area.border
        width: 2 * (area.r + area.border)
        height: width
        radius: width / 2
        color: "transparent"
        border.width: area.border
        border.color: Qt.alpha("black", 0.6)
        antialiasing: true
      }

      Rectangle {
        x: area.cx - area.r
        y: area.cy - area.r
        width: 2 * area.r
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        antialiasing: true
      }

      MouseArea {
        property real grabX: 0
        property real grabY: 0

        anchors.fill: parent
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onPressed: mouse => {
          const dx = mouse.x - area.cx;
          const dy = mouse.y - area.cy;
          if (dx * dx + dy * dy <= area.r * area.r) {
            grabX = dx;
            grabY = dy;
          } else {
            grabX = 0;
            grabY = 0;
            root.place(mouse.x, mouse.y, area.r);
          }
        }
        onPositionChanged: mouse => {
          if (pressed)
            root.place(mouse.x - grabX, mouse.y - grabY, area.r);
        }
        onWheel: wheel => {
          const factor = Math.pow(1.1, wheel.angleDelta.y / 120);
          root.place(area.cx, area.cy, area.r * factor);
        }
      }

      Rectangle {
        id: handle

        readonly property real offset: area.r * Math.SQRT1_2

        x: area.cx + offset - width / 2
        y: area.cy + offset - height / 2
        width: 18
        height: 18
        radius: width / 2
        color: Theme.primary
        border.width: 2
        border.color: Theme.surface
        scale: sizer.pressed || sizer.containsMouse ? 1.2 : 1

        Behavior on scale {
          NumberAnimation {
            duration: Theme.animHover
          }
        }

        MouseArea {
          id: sizer
          anchors.fill: parent
          anchors.margins: -6
          hoverEnabled: true
          cursorShape: Qt.SizeFDiagCursor
          preventStealing: true
          onPositionChanged: mouse => {
            if (!pressed)
              return;
            const p = mapToItem(area, mouse.x, mouse.y);
            root.place(area.cx, area.cy, Math.hypot(p.x - area.cx, p.y - area.cy));
          }
        }
      }
    }
  }

  Text {
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    text: AvatarEditor.error !== "" ? AvatarEditor.error : "Drag to move · scroll or drag the handle to resize"
    color: AvatarEditor.error !== "" ? Theme.error : Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuSubtitleSize - 1
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 8

    Chip {
      icon: "arrow_back"
      text: "Choose another"
      available: !AvatarEditor.saving
      onClicked: AvatarEditor.back()
    }

    Chip {
      icon: AvatarEditor.saving ? "hourglass_empty" : "check"
      text: AvatarEditor.saving ? "Saving" : "Apply"
      selected: true
      available: image.status === Image.Ready && !AvatarEditor.saving
      onClicked: root.apply()
    }
  }
}
