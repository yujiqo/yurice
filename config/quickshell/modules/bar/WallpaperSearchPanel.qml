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
  readonly property real gridMaxHeight: Theme.dropdownMaxHeight - Theme.panelPadding * 2 - controls.height - spacing * 2

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
        height: 44

        TabBar {
          anchors.left: parent.left
          anchors.leftMargin: 2
          anchors.verticalCenter: parent.verticalCenter
          height: 38
          model: WallSearch.providers
          current: WallSearch.provider
          onSelected: id => WallSearch.provider = id
        }

        IconButton {
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

      Item {
        width: parent.width
        height: Theme.menuGap
      }

      TextField {
        id: field
        width: parent.width
        leadingIcon: "search"
        clearable: true
        placeholder: "Search " + (WallSearch.providers.find(p => p.id === WallSearch.provider)?.name ?? "") + "…"
        hint: WallSearch.hasApiKey ? "" : "SFW"
        onAccepted: text => WallSearch.search(text)
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

    delegate: Item {
      id: tile

      required property var modelData
      readonly property bool downloading: WallSearch.downloads[modelData.id] === true
      readonly property bool current: Wallpapers.current === WallSearch.pathFor(modelData)

      width: grid.cellWidth
      height: grid.cellHeight

      Rectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.menuItemRadius - 2
        color: Theme.surfaceContainerHigh
        scale: mouse.pressed ? 0.96 : mouse.containsMouse ? 1.03 : 1
        z: mouse.containsMouse ? 1 : 0

        Behavior on scale {
          NumberAnimation {
            duration: Theme.animMove
            easing.type: Theme.easeOut
          }
        }

        RoundedImage {
          id: thumb
          anchors.fill: parent
          radius: frame.radius
          source: tile.modelData.thumb
          sourceSize: Qt.size(width * 1.5, height * 1.5)
          opacity: status === Image.Ready ? (tile.downloading ? 0.45 : 1) : 0

          Behavior on opacity {
            NumberAnimation {
              duration: Theme.animColor
            }
          }
        }

        Rectangle {
          anchors.left: parent.left
          anchors.bottom: parent.bottom
          anchors.margins: 6
          width: resLabel.implicitWidth + 12
          height: 20
          radius: 10
          color: Qt.alpha(Theme.surface, 0.8)
          opacity: mouse.containsMouse && !tile.downloading ? 1 : 0

          Behavior on opacity {
            NumberAnimation {
              duration: Theme.animHover
            }
          }

          Text {
            id: resLabel
            anchors.centerIn: parent
            text: tile.modelData.resolution
            color: Theme.text
            font.family: Theme.labelFont
            font.pixelSize: 12
          }
        }

        Rectangle {
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 6
          width: 24
          height: 24
          radius: 12
          color: Theme.primary
          scale: tile.current ? 1 : 0
          visible: scale > 0

          Behavior on scale {
            NumberAnimation {
              duration: Theme.animMove
              easing.type: Easing.OutBack
            }
          }

          Icon {
            anchors.centerIn: parent
            text: "check"
            color: Theme.onPrimary
            size: 16
          }
        }

        Spinner {
          anchors.centerIn: parent
          visible: tile.downloading
          tint: Theme.text
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: WallSearch.download(tile.modelData)
        }
      }
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
