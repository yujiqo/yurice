import QtQuick
import qs.theme

Item {
  id: root

  property bool checked: false
  signal toggled

  implicitWidth: 44
  implicitHeight: 26

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
    border.width: root.checked ? 0 : 2
    border.color: Theme.outline
    Behavior on color {
      ColorAnimation {
        duration: Theme.animColor
      }
    }
  }

  Rectangle {
    property real size: root.checked ? 18 : 12
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? root.width - size - 4 : 7
    width: size
    height: size
    radius: size / 2
    color: root.checked ? Theme.textOnPrimary : Theme.outline
    Behavior on x {
      NumberAnimation {
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
    }
    Behavior on size {
      NumberAnimation {
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
    }
    Behavior on color {
      ColorAnimation {
        duration: Theme.animColor
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
}
