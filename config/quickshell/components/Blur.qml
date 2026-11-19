pragma ComponentBehavior: Bound
import QtQuick

Item {
  id: root

  property Item source
  property real amount: 1
  property int levels: 5

  component Pass: ShaderEffectSource {
    property int level
    readonly property int divisor: 1 << Math.max(0, Math.min(level, root.levels))
    anchors.fill: parent
    hideSource: true
    smooth: true
    textureSize: Qt.size(Math.max(1, Math.ceil(root.width / divisor)), Math.max(1, Math.ceil(root.height / divisor)))
  }

  ShaderEffectSource {
    anchors.fill: parent
    sourceItem: root.source
    hideSource: true
    smooth: true
    visible: root.amount < 1
  }

  Pass { id: d1; level: 1; sourceItem: root.source }
  Pass { id: d2; level: 2; sourceItem: d1 }
  Pass { id: d3; level: 3; sourceItem: d2 }
  Pass { id: d4; level: 4; sourceItem: d3 }
  Pass { id: d5; level: 5; sourceItem: d4 }
  Pass { id: d6; level: 6; sourceItem: d5 }
  Pass { id: u5; level: 5; sourceItem: d6 }
  Pass { id: u4; level: 4; sourceItem: u5 }
  Pass { id: u3; level: 3; sourceItem: u4 }
  Pass { id: u2; level: 2; sourceItem: u3 }

  Pass {
    level: 1
    sourceItem: u2
    opacity: root.amount
    visible: root.amount > 0
  }
}
