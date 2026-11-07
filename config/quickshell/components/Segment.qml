import QtQuick
import qs.theme

Item {
  id: root

  property string icon: ""
  property string label: ""
  property color color: Theme.text
  property bool showLabel: false
  property int maxLabelWidth: 300
  property bool clickable: false

  signal clicked(var mouse)
  signal wheel(var event)

  implicitWidth: row.implicitWidth
  implicitHeight: Theme.pillHeight

  Row {
    id: row
    height: parent.height

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      text: root.icon
      visible: text !== ""
      color: root.color
      Behavior on color {
        ColorAnimation {
          duration: Theme.animColor
        }
      }
    }

    Reveal {
      shown: root.showLabel && root.label !== ""
      leading: root.icon !== "" ? Theme.pillIconGap : 0

      Text {
        text: root.label
        width: Math.min(implicitWidth, root.maxLabelWidth)
        elide: Text.ElideRight
        color: Theme.text
        font.family: Theme.labelFont
        font.pixelSize: Theme.labelSize
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.clickable
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => root.clicked(mouse)
  }

  WheelHandler {
    onWheel: event => root.wheel(event)
  }
}
