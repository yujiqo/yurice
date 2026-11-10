pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  open: current === "weeb"
  panel: current === "weeb" ? weebPanel : null
  panelWidth: 340
  padding: (Theme.pillHeight - Theme.iconSize) / 2
  spacing: 0
  clickable: true
  onClicked: mouse => mouse.button === Qt.RightButton ? WeebMode.toggle() : request("weeb")

  Component {
    id: weebPanel

    WeebPanel {}
  }

  Item {
    width: Theme.iconSize
    height: Theme.pillHeight

    Icon {
      anchors.centerIn: parent
      text: WeebMode.icon
      color: Theme.primary
    }
  }

  Reveal {
    shown: root.expanded
    leading: Theme.pillIconGap + 2

    Row {
      Label {
        text: WeebMode.label
      }

      Item {
        width: 3
        height: 1
      }
    }
  }
}
