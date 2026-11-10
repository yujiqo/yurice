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

      Item {
        width: parent.width
        height: 64

        Icon {
          id: heroIcon
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          text: WeebMode.icon
          color: Theme.primary
          size: 44
        }

        Column {
          anchors.left: heroIcon.right
          anchors.leftMargin: 14
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Label {
            text: WeebMode.label
            pixelSize: 30
          }

          Label {
            width: parent.width
            text: `${Wallpapers.safeCount} of ${Wallpapers.allWallpapers.length} wallpapers marked safe`
            color: Theme.textVariant
            pixelSize: Theme.menuSubtitleSize
          }
        }
      }

      Rectangle {
        width: parent.width
        height: toggles.implicitHeight + 8
        radius: Theme.menuItemRadius
        color: Theme.surfaceContainer

        Column {
          id: toggles
          y: 4
          width: parent.width

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

            InfoRow {
              required property var modelData

              width: parent.width
              icon: modelData.icon
              label: modelData.label
              value: ""

              Switch {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                checked: WeebMode.isHidden(parent.modelData.name)
                onToggled: WeebMode.setHidden(parent.modelData.name, !checked)
              }
            }
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
