pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  property bool showFilters: false
  property bool editingKey: false
  readonly property bool keepOpen: WallSearch.busy || editingKey
  readonly property bool searching: WallSearch.searching
  property real maxHeight: Theme.dropdownMaxHeight - Theme.panelPadding * 2
  readonly property real gridMaxHeight: maxHeight - controls.height - spacing * 2

  spacing: Theme.menuGap

  Component.onCompleted: {
    field.text = WallSearch.query;
    field.focusInput();
  }

  function togglePurity(index) {
    if (WallSearch.hasApiKey)
      WallSearch.toggleBit("purity", index);
    else
      editingKey = true;
  }

  Collapse {
    id: controls
    width: parent.width
    shown: !root.searching

    Column {
      width: parent.width

      Item {
        width: parent.width
        height: field.implicitHeight

        TextField {
          id: field
          anchors.left: parent.left
          anchors.right: tune.left
          anchors.rightMargin: 6
          anchors.verticalCenter: parent.verticalCenter
          leadingIcon: "search"
          clearable: true
          placeholder: "Search Wallhaven…"
          escapeLeaves: true
          hint: WallSearch.hasApiKey && !WeebMode.hidesAdultFilters ? "" : "SFW"
          onAccepted: text => WallSearch.search(text)
        }

        IconButton {
          id: tune
          anchors.right: parent.right
          anchors.rightMargin: 2
          anchors.verticalCenter: parent.verticalCenter
          icon: "tune"
          iconColor: root.showFilters ? Theme.primary : Theme.textVariant
          color: root.showFilters ? Theme.secondaryContainer : "transparent"
          onClicked: root.showFilters = !root.showFilters
        }
      }

      Collapse {
        width: parent.width
        leading: Theme.menuGap
        shown: root.showFilters

        Column {
          width: parent.width
          bottomPadding: 6

          Column {
            width: parent.width
            spacing: 8

            FilterRow {
              title: "Type"
              Chip {
                text: "General"
                selected: WallSearch.categories[0] === "1"
                onClicked: WallSearch.toggleBit("categories", 0)
              }
              Chip {
                text: "Anime"
                visible: !WeebMode.hidesAnimeFilter
                selected: WallSearch.categories[1] === "1"
                onClicked: WallSearch.toggleBit("categories", 1)
              }
              Chip {
                text: "People"
                selected: WallSearch.categories[2] === "1"
                onClicked: WallSearch.toggleBit("categories", 2)
              }
            }

            FilterRow {
              title: "Purity"
              visible: !WeebMode.hidesAdultFilters
              Chip {
                text: "SFW"
                selected: WallSearch.purity[0] === "1"
                onClicked: WallSearch.toggleBit("purity", 0)
              }
              Chip {
                text: "Sketchy"
                selected: WallSearch.purity[1] === "1"
                onClicked: root.togglePurity(1)
              }
              Chip {
                text: "NSFW"
                selected: WallSearch.purity[2] === "1"
                onClicked: root.togglePurity(2)
              }
            }

            FilterRow {
              title: "Sort"
              Repeater {
                model: [["relevance", "Relevance"], ["toplist", "Top"], ["date_added", "Latest"], ["random", "Random"]]

                Chip {
                  required property var modelData
                  text: modelData[1]
                  selected: WallSearch.sorting === modelData[0]
                  onClicked: WallSearch.setFilter("sorting", modelData[0])
                }
              }
            }

            FilterRow {
              title: "Size"
              Chip {
                icon: "aspect_ratio"
                text: "At least " + WallSearch.resolution
                selected: WallSearch.atleast
                onClicked: WallSearch.setFilter("atleast", !WallSearch.atleast)
              }
            }

            FilterRow {
              title: "Key"
              Chip {
                icon: "key"
                text: WallSearch.hasApiKey ? "Change API key" : "Add API key"
                selected: root.editingKey
                onClicked: root.editingKey = !root.editingKey
              }
            }
          }

          Collapse {
            width: parent.width
            leading: 8
            shown: root.editingKey
            onShownChanged: {
              if (shown) {
                keyField.text = WallSearch.apiKey;
                keyField.focusInput();
              }
            }

            Column {
              width: parent.width
              spacing: 4

              PasswordField {
                id: keyField
                width: parent.width
                placeholder: "Wallhaven API key"
                navigable: true
                onAccepted: key => {
                  WallSearch.setApiKey(key);
                  root.editingKey = false;
                  field.focusInput();
                }
                onCanceled: {
                  root.editingKey = false;
                  field.focusInput();
                }
              }

              Text {
                leftPadding: 10
                text: "Get it at wallhaven.cc/settings/account · Enter saves, empty removes"
                color: Theme.textVariant
                font.family: Theme.labelFont
                font.pixelSize: Theme.menuSubtitleSize - 2
              }
            }
          }
        }
      }
    }
  }

  SearchResults {
    feed: WallSearch
    label: "wallpapers"
    emptyText: "No wallpapers found"
    tint: Theme.wallpaper
    maxHeight: root.gridMaxHeight
    busyFor: item => WallSearch.downloads[item.id] === true
    checkedFor: item => Wallpapers.current === WallSearch.pathFor(item)
    onActivated: item => WallSearch.download(item)
  }

  component FilterRow: Row {
    property string title
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: 60
      leftPadding: 10
      text: parent.title
      color: Theme.textVariant
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuSubtitleSize
    }
  }
}
