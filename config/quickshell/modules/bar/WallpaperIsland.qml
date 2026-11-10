pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

IconIsland {
  id: root

  property string tab: "library"

  panels: ({
      wallpapers: managerPanel
    })
  panelWidth: Theme.searchPanelWidth
  icon: "wallpaper_slideshow"
  iconColor: Theme.wallpaper
  working: WallSearch.searching || WallpaperTools.upscaling
  labelShown: expanded || working
  label: WallSearch.searching ? "Searching wallpapers…" : WallpaperTools.upscaling ? WallpaperTools.status : "Manage wallpapers"
  onClicked: request("wallpapers")

  Component {
    id: managerPanel

    WallpaperPanel {
      tab: root.tab
      onTabSelected: id => root.tab = id
    }
  }
}
