pragma ComponentBehavior: Bound
import QtQuick

Item {
  id: root

  property alias source: image.source
  property alias sourceSize: image.sourceSize
  property real radius: 0
  readonly property alias status: image.status

  Image {
    id: image
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    visible: false
  }

  ShaderEffect {
    property Image source: image
    property size size: Qt.size(width, height)
    property real radius: Math.min(root.radius, Math.min(width, height) / 2)
    property vector4d uvRect: {
      const iw = image.implicitWidth;
      const ih = image.implicitHeight;
      if (iw <= 0 || ih <= 0 || width <= 0 || height <= 0)
        return Qt.vector4d(0, 0, 1, 1);
      const boxAspect = width / height;
      const imageAspect = iw / ih;
      if (imageAspect > boxAspect) {
        const sx = boxAspect / imageAspect;
        return Qt.vector4d((1 - sx) / 2, 0, sx, 1);
      }
      const sy = imageAspect / boxAspect;
      return Qt.vector4d(0, (1 - sy) / 2, 1, sy);
    }

    anchors.fill: parent
    visible: image.status === Image.Ready
    fragmentShader: Qt.resolvedUrl("../shaders/roundedimage.frag.qsb")
  }
}
