import QtQuick
import qs.theme
import qs.components

Column {
  id: root

  property string tab: "library"
  readonly property bool keepOpen: content.item?.keepOpen ?? false
  readonly property real contentMaxHeight: Theme.dropdownMaxHeight - Theme.panelPadding * 2 - tabs.height - spacing

  signal tabSelected(string id)

  spacing: Theme.menuGap

  TabBar {
    id: tabs
    anchors.horizontalCenter: parent.horizontalCenter
    height: 38
    model: [
      {
        id: "library",
        name: "Wallpapers",
        icon: "photo_library"
      },
      {
        id: "search",
        name: "Search",
        icon: "travel_explore"
      }
    ]
    current: root.tab
    onSelected: id => root.tabSelected(id)
  }

  Loader {
    id: content
    width: parent.width
    focus: true
    sourceComponent: root.tab === "search" ? searchTab : libraryTab
  }

  Component {
    id: searchTab

    WallpaperSearchPanel {
      maxHeight: root.contentMaxHeight
    }
  }

  Component {
    id: libraryTab

    WallpaperLibrary {
      maxHeight: root.contentMaxHeight
    }
  }
}
