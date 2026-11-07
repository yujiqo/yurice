import QtQuick
import qs.theme
import qs.components

Island {
  id: root

  padding: (Theme.pillHeight - Theme.iconSize) / 2
  spacing: 0

  Item {
    width: Theme.iconSize
    height: Theme.pillHeight

    Icon {
      anchors.centerIn: parent
      text: "palette"
      color: Theme.tertiary
    }
  }

  Reveal {
    shown: root.expanded
    leading: Theme.pillIconGap + 2

    Row {
      Label {
        text: "Booru"
      }

      Item {
        width: 3
        height: 1
      }
    }
  }
}
