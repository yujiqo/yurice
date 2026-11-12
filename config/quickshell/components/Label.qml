pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Item {
  id: root

  property alias text: label.text
  property alias color: label.color
  property real maxWidth: Infinity
  property int pixelSize: Theme.labelSize
  property bool smooth: false

  implicitWidth: Math.min(smooth ? widthSpring.value : label.implicitWidth, maxWidth)
  implicitHeight: metrics.height
  clip: smooth && widthSpring.running

  onTextChanged: {
    if (smooth)
      fade.restart();
  }

  Spring {
    id: widthSpring
    target: label.implicitWidth
    Component.onCompleted: snap()
  }

  NumberAnimation {
    id: fade
    target: label
    property: "opacity"
    from: 0
    to: 1
    duration: Theme.animMove
    easing.type: Easing.OutQuad
  }

  FontMetrics {
    id: metrics
    font: label.font
  }

  Text {
    id: label
    width: root.smooth ? implicitWidth : root.width
    anchors.baseline: parent.top
    anchors.baselineOffset: metrics.ascent
    elide: root.smooth ? Text.ElideNone : Text.ElideRight
    color: Theme.text
    font.family: Theme.labelFont
    font.pixelSize: root.pixelSize
  }
}
