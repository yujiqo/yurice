pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.services

Item {
  id: root

  property string path: ""
  property size sourceSize: Qt.size(width * 2, height * 2)
  property color fallbackColor: Theme.surfaceContainer
  property color iconColor: Theme.primary
  property real iconSize: width * 0.55
  property RoundedImage front: imageA
  readonly property RoundedImage back: front === imageA ? imageB : imageA
  readonly property url target: path === "" ? "" : Paths.fileUrl(path) + (AvatarEditor.revision > 0 ? "?v=" + AvatarEditor.revision.toFixed(0) : "")
  readonly property bool ready: front.status === Image.Ready

  onTargetChanged: load()
  Component.onCompleted: imageA.source = target

  function load() {
    if (front.source === target)
      return;
    back.source = target;
    settle(back);
  }

  function settle(image) {
    if (image !== back || image.source !== target)
      return;
    if (image.status === Image.Ready || image.status === Image.Error || target.toString() === "")
      front = image;
  }

  Rectangle {
    anchors.fill: parent
    radius: width / 2
    color: root.fallbackColor
    opacity: root.ready ? 0 : 1

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.animMove
      }
    }

    Icon {
      anchors.centerIn: parent
      text: "person"
      color: root.iconColor
      size: root.iconSize
    }
  }

  RoundedImage {
    id: imageA
    anchors.fill: parent
    radius: width / 2
    sourceSize: root.sourceSize
    opacity: root.front === imageA ? 1 : 0
    onStatusChanged: root.settle(imageA)

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.animMove
        easing.type: Easing.InOutQuad
      }
    }
  }

  RoundedImage {
    id: imageB
    anchors.fill: parent
    radius: width / 2
    sourceSize: root.sourceSize
    opacity: root.front === imageB ? 1 : 0
    onStatusChanged: root.settle(imageB)

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.animMove
        easing.type: Easing.InOutQuad
      }
    }
  }
}
