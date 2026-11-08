import QtQuick
import qs.theme

Item {
  id: root

  property url source
  property string resolution: ""
  property color resolutionColor: Theme.text
  property bool checked: false
  property bool busy: false
  property bool dimmed: busy
  property bool showResolution: hovered && !busy
  readonly property bool hovered: mouse.containsMouse
  readonly property alias frame: frame
  default property alias overlay: frame.data

  signal clicked

  Rectangle {
    id: frame
    anchors.fill: parent
    anchors.margins: 3
    radius: Theme.menuItemRadius - 2
    color: Theme.surfaceContainerHigh
    scale: mouse.pressed ? 0.96 : mouse.containsMouse ? 1.03 : 1
    z: mouse.containsMouse ? 1 : 0

    Behavior on scale {
      NumberAnimation {
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
    }

    RoundedImage {
      anchors.fill: parent
      radius: frame.radius
      source: root.source
      sourceSize: Qt.size(width * 1.5, height * 1.5)
      opacity: status === Image.Ready ? (root.dimmed ? 0.45 : 1) : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animColor
        }
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.margins: 6
      width: resLabel.implicitWidth + 12
      height: 20
      radius: 10
      color: Qt.alpha(Theme.surface, 0.8)
      opacity: root.showResolution && root.resolution !== "" ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animHover
        }
      }

      Text {
        id: resLabel
        anchors.centerIn: parent
        text: root.resolution
        color: root.resolutionColor
        font.family: Theme.labelFont
        font.pixelSize: 12
      }
    }

    Rectangle {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 6
      width: 24
      height: 24
      radius: 12
      color: Theme.primary
      scale: root.checked ? 1 : 0
      visible: scale > 0

      Behavior on scale {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Easing.OutBack
        }
      }

      Icon {
        anchors.centerIn: parent
        text: "check"
        color: Theme.textOnPrimary
        size: 16
      }
    }

    Spinner {
      anchors.centerIn: parent
      visible: root.busy
      tint: Theme.text
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.clicked()
    }
  }
}
