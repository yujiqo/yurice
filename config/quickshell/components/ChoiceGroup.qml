pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Item {
  id: root

  property var options: []
  property var current
  signal selected(var value)

  readonly property real gap: 4
  readonly property real compactWidth: 52
  readonly property real selectedWidth: width - (options.length - 1) * (compactWidth + gap)

  implicitHeight: 44

  Row {
    spacing: root.gap

    Repeater {
      model: root.options

      Rectangle {
        id: button

        required property var modelData
        required property int index
        readonly property bool active: root.current === modelData.value
        readonly property bool first: index === 0
        readonly property bool last: index === root.options.length - 1
        readonly property real outer: height / 2
        property real inner: active ? height / 2 : 8

        function keyActivate() {
          root.selected(modelData.value);
        }

        activeFocusOnTab: true

        FocusRing {
          radius: 8
        }

        width: active ? root.selectedWidth : root.compactWidth
        height: root.height
        topLeftRadius: first ? outer : inner
        bottomLeftRadius: first ? outer : inner
        topRightRadius: last ? outer : inner
        bottomRightRadius: last ? outer : inner
        color: active ? Theme.primary : buttonMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
        scale: buttonMouse.pressed ? 0.95 : 1

        Behavior on width {
          NumberAnimation {
            duration: Theme.animSlide
            easing.type: Theme.easeOut
          }
        }
        Behavior on inner {
          NumberAnimation {
            duration: Theme.animSlide
            easing.type: Theme.easeOut
          }
        }
        Behavior on color {
          ColorAnimation {
            duration: Theme.animColor
          }
        }
        Behavior on scale {
          NumberAnimation {
            duration: Theme.animPress
          }
        }

        Row {
          anchors.centerIn: parent
          height: parent.height

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: button.modelData.icon
            color: button.active ? Theme.textOnPrimary : Theme.textVariant
            size: Theme.menuIconSize
          }

          Reveal {
            anchors.verticalCenter: parent.verticalCenter
            shown: button.active
            leading: 8

            Label {
              text: button.modelData.label
              color: Theme.textOnPrimary
              pixelSize: Theme.menuSubtitleSize + 1
            }
          }
        }

        MouseArea {
          id: buttonMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.selected(button.modelData.value)
        }
      }
    }
  }
}
