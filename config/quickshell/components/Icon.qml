import QtQuick
import qs.theme

Text {
  property real size: Theme.iconSize
  property real fill: 0
  property real weight: 400

  font.family: Theme.iconFont
  font.pixelSize: size
  font.variableAxes: ({
      "opsz": Math.max(20, Math.min(48, size)),
      "wght": weight,
      "FILL": fill,
      "GRAD": 0
    })
  renderType: Text.CurveRendering
}
