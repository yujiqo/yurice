// SliderRow.qml — icon + slider, adjustable by drag or mouse wheel. Shared by brightness and
// volume so neither widget restyles a Slider from scratch.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.theme

RowLayout {
  id: root

  property string icon: ""
  property real value: 0 // 0..1, set by the consumer; may change externally at any time
  signal moved(real value)
  signal iconClicked()

  spacing: Theme.s3

  MouseArea {
    implicitWidth: iconText.implicitWidth
    implicitHeight: iconText.implicitHeight
    onClicked: root.iconClicked()
    Text {
      id: iconText
      text: root.icon
      color: Theme.text
      font.pixelSize: Theme.fsNormal
    }
  }

  Slider {
    id: slider
    Layout.fillWidth: true
    from: 0
    to: 1

    Component.onCompleted: value = root.value
    // re-sync from the outside world, but never fight an in-progress drag
    Connections {
      target: root
      function onValueChanged() { if (!slider.pressed) slider.value = root.value }
    }
    onMoved: root.moved(value)

    background: Rectangle {
      x: slider.leftPadding
      y: slider.topPadding + slider.availableHeight / 2 - height / 2
      width: slider.availableWidth
      height: Theme.s1
      radius: Theme.rSmall
      color: Theme.surface

      Rectangle {
        width: slider.visualPosition * parent.width
        height: parent.height
        radius: Theme.rSmall
        color: Theme.accent
      }
    }

    handle: Rectangle {
      x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
      y: slider.topPadding + slider.availableHeight / 2 - height / 2
      width: Theme.s3 * 2
      height: Theme.s3 * 2
      radius: width / 2
      color: Theme.text
    }

    // WheelHandler (not MouseArea) for scroll: a PointerHandler only grabs the wheel axis,
    // so it adds scroll support without contending with the Slider's own built-in press/drag
    // handling the way a MouseArea overlay did (that was the drag-and-scroll-both-broken bug).
    WheelHandler {
      onWheel: event => {
        const step = 0.05
        const next = event.angleDelta.y > 0
          ? Math.min(slider.value + step, 1)
          : Math.max(slider.value - step, 0)
        slider.value = next
        root.moved(next)
      }
    }
  }
}
