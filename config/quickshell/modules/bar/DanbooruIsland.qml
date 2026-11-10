pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

IconIsland {
  id: root

  panels: ({
      danbooru: danbooruPanel
    })
  panelWidth: Theme.searchPanelWidth
  icon: "palette"
  iconColor: Theme.tertiary
  working: Danbooru.searching || Danbooru.downloading
  labelShown: expanded || working || Danbooru.notice !== ""
  label: Danbooru.searching ? "Searching Danbooru…" : Danbooru.downloading ? "Saving image…" : Danbooru.notice || "Danbooru"
  onClicked: request("danbooru")

  Component {
    id: danbooruPanel

    DanbooruPanel {}
  }
}
