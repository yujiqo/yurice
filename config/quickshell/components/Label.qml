import QtQuick
import qs.theme

Item {
  id: root

  property alias text: label.text
  property alias color: label.color
  property real maxWidth: Infinity
  property int pixelSize: Theme.labelSize

  implicitWidth: Math.min(label.implicitWidth, maxWidth)
  implicitHeight: metrics.height

  FontMetrics {
    id: metrics
    font: label.font
  }

  Text {
    id: label
    width: root.width
    anchors.baseline: parent.top
    anchors.baselineOffset: metrics.ascent
    elide: Text.ElideRight
    color: Theme.text
    font.family: Theme.labelFont
    font.pixelSize: root.pixelSize
  }
}
