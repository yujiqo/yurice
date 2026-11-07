import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  open: current === "danbooru"
  panel: current === "danbooru" ? danbooruPanel : null
  panelWidth: Theme.searchPanelWidth
  padding: (Theme.pillHeight - Theme.iconSize) / 2
  spacing: 0
  clickable: true
  onClicked: request("danbooru")

  readonly property bool working: Danbooru.searching || Danbooru.downloading

  Component {
    id: danbooruPanel

    DanbooruPanel {}
  }

  Item {
    width: Theme.iconSize
    height: Theme.pillHeight

    Icon {
      anchors.centerIn: parent
      text: "palette"
      color: Theme.tertiary
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
      tint: Theme.tertiary
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
    shown: root.expanded || root.working || Danbooru.notice !== ""
    leading: Theme.pillIconGap + 2

    Row {
      Label {
        text: Danbooru.searching ? "Searching Danbooru…" : Danbooru.downloading ? "Saving image…" : Danbooru.notice || "Danbooru"
      }

      Item {
        width: 3
        height: 1
      }
    }
  }
}
