import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  property string tab: "library"

  open: current === "wallpapers"
  panel: current === "wallpapers" ? managerPanel : null
  panelWidth: Theme.searchPanelWidth
  padding: (Theme.pillHeight - Theme.iconSize) / 2
  spacing: 0
  clickable: true
  onClicked: request("wallpapers")

  Component {
    id: managerPanel

    WallpaperPanel {
      tab: root.tab
      onTabSelected: id => root.tab = id
    }
  }

  Item {
    width: Theme.iconSize
    height: Theme.pillHeight

    Icon {
      anchors.centerIn: parent
      text: "wallpaper_slideshow"
      color: Theme.wallpaper
      opacity: WallSearch.searching ? 0 : 1
      scale: WallSearch.searching ? 0.6 : 1

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
      tint: Theme.wallpaper
      visible: opacity > 0
      opacity: WallSearch.searching ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animHover
        }
      }
    }
  }

  Reveal {
    shown: root.expanded || WallSearch.searching
    leading: Theme.pillIconGap + 2

    Row {
      Label {
        text: WallSearch.searching ? "Searching wallpapers…" : "Manage wallpapers"
      }

      Item {
        width: 3
        height: 1
      }
    }
  }
}
