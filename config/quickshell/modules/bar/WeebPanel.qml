pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  readonly property var items: [
    {
      name: "hideWallpapers",
      icon: "wallpaper",
      label: "Unsafe wallpapers"
    },
    {
      name: "hideDanbooru",
      icon: "palette",
      label: "Danbooru search"
    },
    {
      name: "hideAnimeFilter",
      icon: "filter_alt",
      label: "Anime search filter"
    },
    {
      name: "hideAdultFilters",
      icon: "shield",
      label: "Sketchy and NSFW filters"
    },
    {
      name: "hideAvatar",
      icon: "person",
      label: "Profile picture"
    }
  ]

  spacing: 0

  Collapse {
    width: parent.width
    shown: !WeebMode.normie

    Column {
      width: parent.width
      spacing: 8
      bottomPadding: 8

      PanelHeader {
        icon: WeebMode.icon
        title: WeebMode.label
        subtitle: `${Wallpapers.safeCount} of ${Wallpapers.allWallpapers.length} wallpapers marked safe`
      }

      Card {
        Item {
          width: parent.width
          height: 30

          Label {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "Hide in normie mode"
            pixelSize: Theme.menuSubtitleSize
          }
        }

        Repeater {
          model: root.items

          SwitchRow {
            required property var modelData
          
            icon: modelData.icon
            label: modelData.label
            checked: WeebMode.isHidden(modelData.name)
            onToggled: WeebMode.setHidden(modelData.name, !checked)
          }
        }
      }
    }
  }

  ChoiceGroup {
    width: parent.width
    options: [
      {
        value: "weeb",
        icon: "visibility",
        label: "Weeb"
      },
      {
        value: "normie",
        icon: "visibility_off",
        label: "Normie"
      }
    ]
    current: WeebMode.mode
    onSelected: value => WeebMode.set(value)
  }
}
