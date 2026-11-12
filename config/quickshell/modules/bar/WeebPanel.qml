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
  readonly property var islands: Islands.list.filter(island => island.id !== "weeb" && Islands.enabled(island.id))
  property string tab: "content"

  spacing: 0

  TabTransition {
    id: transition
    current: root.tab
    order: ["content", "islands", "names"]
  }

  component HiddenTitle: Item {
    width: parent.width
    height: 30

    Label {
      anchors.left: parent.left
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      text: `Hide in ${WeebMode.secondaryLabel} mode`
      pixelSize: Theme.menuSubtitleSize
    }
  }

  component NameRow: Item {
    id: row

    property string mode: ""

    width: parent.width
    height: 48

    Icon {
      id: rowIcon
      anchors.left: parent.left
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      width: 24
      horizontalAlignment: Text.AlignHCenter
      text: WeebMode.iconFor(row.mode)
      color: Theme.primary
      size: Theme.menuIconSize - 2
    }

    TextField {
      id: field
      anchors.left: rowIcon.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      implicitHeight: 40
      placeholder: row.mode === "normie" ? "Normie" : "Weeb"
      placeholderOpacity: 0.45
      escapeLeaves: true
      hint: inputActiveFocus ? "Enter" : ""
      onAccepted: value => {
        WeebMode.setName(row.mode, value);
        field.blur();
      }
      onInputActiveFocusChanged: {
        if (!inputActiveFocus)
          field.text = WeebMode.name(row.mode);
      }
      Component.onCompleted: text = WeebMode.name(row.mode)
    }
  }

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
        smoothTitle: true
        subtitle: `${Wallpapers.safeCount} of ${Wallpapers.allWallpapers.length} wallpapers marked safe`
      }

      TabBar {
        anchors.horizontalCenter: parent.horizontalCenter
        height: 38
        model: [
          {
            id: "content",
            name: "Content",
            icon: "shield"
          },
          {
            id: "islands",
            name: "Islands",
            icon: "view_column"
          },
          {
            id: "names",
            name: "Names",
            icon: "edit"
          }
        ]
        current: root.tab
        onSelected: id => root.tab = id
      }

      Column {
        width: parent.width
        opacity: transition.fade
        transform: Translate {
          x: transition.slide
        }

        Card {
          visible: transition.shown === "content"

          HiddenTitle {}

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

        Card {
          visible: transition.shown === "islands"

          HiddenTitle {}

          Flickable {
            id: islandFlick
            width: parent.width
            height: Math.min(islandColumn.implicitHeight, 266)
            contentHeight: islandColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
              id: islandColumn
              width: islandFlick.width

              Repeater {
                model: root.islands

                SwitchRow {
                  required property var modelData

                  icon: modelData.icon
                  label: modelData.label
                  checked: WeebMode.islandHidden(modelData.id)
                  onToggled: WeebMode.setIslandHidden(modelData.id, !checked)
                }
              }
            }
          }
        }

        Card {
          visible: transition.shown === "names"

          NameRow {
            mode: "weeb"
          }

          NameRow {
            mode: "normie"
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
        icon: WeebMode.primaryIcon,
        label: WeebMode.primaryLabel
      },
      {
        value: "normie",
        icon: WeebMode.secondaryIcon,
        label: WeebMode.secondaryLabel
      }
    ]
    current: WeebMode.mode
    onSelected: value => WeebMode.set(value)
  }

  Scrollbar {
    flickable: islandFlick
  }
}
