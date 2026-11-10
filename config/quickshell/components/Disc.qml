pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs.theme

Item {
  id: root

  property string art: ""
  property real angle: 0
  readonly property real size: Math.min(width, height)
  property RoundedImage latest: coverA
  property RoundedImage shown: coverA
  readonly property int artStatus: art === "" ? Image.Null : latest.status

  onArtChanged: {
    latest = shown === coverA ? coverB : coverA;
    latest.source = art;
    settle();
  }

  function settle() {
    if (art === "" || latest.status === Image.Ready || latest.status === Image.Error)
      shown = latest;
  }

  Rectangle {
    anchors.centerIn: parent
    width: root.size
    height: root.size
    radius: width / 2
    color: Theme.surfaceContainerHigh
    border.width: 1
    border.color: Qt.alpha(Theme.text, 0.12)
  }

  Item {
    anchors.centerIn: parent
    width: root.size
    height: root.size
    rotation: root.angle

    Repeater {
      model: 7

      Rectangle {
        required property int index
        readonly property real ratio: 0.66 + index * 0.045

        anchors.centerIn: parent
        width: root.size * ratio
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.text, index % 2 ? 0.07 : 0.12)
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: root.size * 0.6
      height: width
      radius: width / 2
      color: Theme.primaryContainer

      Icon {
        anchors.centerIn: parent
        visible: root.shown.status !== Image.Ready
        text: "music_note"
        color: Theme.textOnPrimaryContainer
        size: parent.width * 0.4
        fill: 1
      }

      Cover {
        id: coverA
      }

      Cover {
        id: coverB
      }
    }

    Rectangle {
      x: parent.width / 2 + root.size * 0.21
      y: parent.height / 2 - 3
      width: 6
      height: 6
      radius: 3
      color: Qt.alpha(Theme.text, 0.25)
    }
  }

  Shape {
    anchors.centerIn: parent
    width: root.size
    height: root.size
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: 0
      strokeColor: "transparent"
      fillGradient: ConicalGradient {
        centerX: root.size / 2
        centerY: root.size / 2
        angle: 45
        GradientStop {
          position: 0
          color: Qt.alpha(Theme.text, 0)
        }
        GradientStop {
          position: 0.08
          color: Qt.alpha(Theme.text, 0.09)
        }
        GradientStop {
          position: 0.18
          color: Qt.alpha(Theme.text, 0)
        }
        GradientStop {
          position: 0.5
          color: Qt.alpha(Theme.text, 0)
        }
        GradientStop {
          position: 0.58
          color: Qt.alpha(Theme.text, 0.09)
        }
        GradientStop {
          position: 0.68
          color: Qt.alpha(Theme.text, 0)
        }
        GradientStop {
          position: 1
          color: Qt.alpha(Theme.text, 0)
        }
      }

      PathAngleArc {
        centerX: root.size / 2
        centerY: root.size / 2
        radiusX: root.size / 2
        radiusY: root.size / 2
        startAngle: 0
        sweepAngle: 360
      }
    }
  }

  Rectangle {
    anchors.centerIn: parent
    width: 12
    height: 12
    radius: 6
    color: Theme.surface
    border.width: 2
    border.color: Qt.alpha(Theme.text, 0.15)
  }

  component Cover: RoundedImage {
    id: cover

    anchors.fill: parent
    radius: width / 2
    sourceSize: Qt.size(width * 2, height * 2)
    visible: root.shown === cover
    onStatusChanged: root.settle()
  }
}
