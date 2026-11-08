import QtQuick
import Quickshell
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

  Item {
    width: parent.width
    height: 56
    visible: root.searching

    Row {
      anchors.centerIn: parent
      spacing: 6

      Spinner {
        anchors.verticalCenter: parent.verticalCenter
        tint: Theme.wallpaper
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Searching wallpapers…"
        color: Theme.text
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuTitleSize
      }
    }
  }

  Text {
    width: parent.width
    height: 56
    visible: WallSearch.phase === "error" || (WallSearch.phase === "results" && WallSearch.results.length === 0)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: WallSearch.phase === "error" ? WallSearch.error : "No wallpapers found"
    color: Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuTitleSize
  }

  GridView {
    id: grid

    readonly property int columns: 3

    width: parent.width
    height: Math.min(contentHeight, root.gridMaxHeight)
    visible: WallSearch.phase === "results" && WallSearch.results.length > 0
    clip: true
    cellWidth: width / columns
    cellHeight: Theme.thumbHeight + 6
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    model: ScriptModel {
      values: WallSearch.results
    }
    onAtYEndChanged: {
      if (atYEnd && contentHeight > height)
        WallSearch.loadMore();
    }

    footer: Item {
      width: grid.width
      height: WallSearch.loadingMore ? 40 : 0

      Spinner {
        anchors.centerIn: parent
        visible: WallSearch.loadingMore
        tint: Theme.wallpaper
      }
    }

    delegate: ImageTile {
      required property var modelData

      width: grid.cellWidth
      height: grid.cellHeight
      source: modelData.thumb
      resolution: modelData.resolution
      busy: WallSearch.downloads[modelData.id] === true
      checked: Wallpapers.current === WallSearch.pathFor(modelData)
      onClicked: WallSearch.download(modelData)
    }
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
