pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Island {
  id: root

  property string icon: ""
  property color iconColor: Theme.primary
  property string label: ""
  property bool working: false
  property bool labelShown: expanded
  property bool smoothLabel: false

  padding: (Theme.pillHeight - Theme.iconSize) / 2
  spacing: 0
  clickable: true

  Item {
    width: Theme.iconSize
    height: Theme.pillHeight

    Icon {
      anchors.centerIn: parent
      text: root.icon
      color: root.iconColor
      opacity: root.working ? 0 : 1
      scale: root.working ? 0.6 : 1

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animHover
        }
      }
      Behavior on scale {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }
    }

    Spinner {
      anchors.centerIn: parent
      width: Theme.iconSize
      height: Theme.iconSize
      size: Theme.iconSize
      tint: root.iconColor
      visible: opacity > 0
      opacity: root.working ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animHover
        }
      }
    }
  }

  Reveal {
    shown: root.labelShown
    leading: Theme.pillIconGap + 2

    Row {
      Label {
        text: root.label
        smooth: root.smoothLabel
      }

      Item {
        width: 3
        height: 1
      }
    }
  }
}
