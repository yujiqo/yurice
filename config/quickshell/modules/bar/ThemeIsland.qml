import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  open: current === "theme"
  panel: current === "theme" ? themePanel : null
  panelWidth: 340
  padding: (Theme.pillHeight - Theme.iconSize) / 2
  spacing: 0
  clickable: true
  onClicked: mouse => mouse.button === Qt.RightButton ? ThemeMode.toggle() : request("theme")

  Component {
    id: themePanel

    ThemePanel {}
  }

  Item {
    width: Theme.iconSize
    height: Theme.pillHeight

    Icon {
      anchors.centerIn: parent
      text: "contrast"
      color: Theme.primary
    }
  }

  Reveal {
    shown: root.expanded
    leading: Theme.pillIconGap + 2

    Row {
      Label {
        text: ThemeMode.label
      }

      Item {
        width: 3
        height: 1
      }
    }
  }
}
