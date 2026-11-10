pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  property bool editingKey: false
  readonly property bool keepOpen: Danbooru.busy || editingKey
  readonly property bool searching: Danbooru.searching
  readonly property real gridMaxHeight: Theme.dropdownMaxHeight - Theme.panelPadding * 2 - controls.height - spacing * 2

  spacing: Theme.menuGap

  Component.onCompleted: {
    Danbooru.watching = true;
    field.text = Danbooru.query;
    field.focusInput();
  }
  Component.onDestruction: Danbooru.watching = false

  Collapse {
    id: controls
    width: parent.width
    shown: !root.searching

    Column {
      width: parent.width
      spacing: Theme.menuGap

      TextField {
        id: field
        width: parent.width
        leadingIcon: "sell"
        clearable: true
        placeholder: "Tags, up to 2 (e.g. scenery sky)"
        escapeLeaves: true
        hint: Danbooru.safeOnly ? "SFW" : ""
        onAccepted: text => Danbooru.search(text)

        IconButton {
          width: 28
          height: 28
          icon: Danbooru.safeOnly ? "shield" : "remove_moderator"
          iconColor: Danbooru.safeOnly ? Theme.primary : Theme.textVariant
          onClicked: Danbooru.setSafeOnly(!Danbooru.safeOnly)
        }

        IconButton {
          width: 28
          height: 28
          icon: "key"
          iconColor: root.editingKey || Danbooru.hasApiKey ? Theme.primary : Theme.textVariant
          color: root.editingKey ? Theme.secondaryContainer : "transparent"
          onClicked: root.editingKey = !root.editingKey
        }
      }

      Collapse {
        width: parent.width
        shown: root.editingKey
        onShownChanged: {
          if (shown) {
            loginField.text = Danbooru.login;
            keyField.text = Danbooru.apiKey;
            loginField.focusInput();
          }
        }

        Column {
          width: parent.width
          spacing: 6

          TextField {
            id: loginField
            width: parent.width
            leadingIcon: "person"
            placeholder: "Danbooru username"
            onAccepted: keyField.focusInput()
            onCanceled: {
              root.editingKey = false;
              field.focusInput();
            }
          }

          PasswordField {
            id: keyField
            width: parent.width
            placeholder: "Danbooru API key"
            navigable: true
            onAccepted: key => {
              Danbooru.setCredentials(loginField.text, key);
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
            text: "Create one at danbooru.donmai.us → My Account → API Key · Enter saves, empty removes"
            color: Theme.textVariant
            font.family: Theme.labelFont
            font.pixelSize: Theme.menuSubtitleSize - 2
          }
        }
      }
    }
  }

  Rectangle {
    width: parent.width
    height: 72
    radius: Theme.menuItemRadius
    color: Theme.surfaceContainer
    visible: Danbooru.down && !root.searching

    Row {
      anchors.left: parent.left
      anchors.leftMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      spacing: 12

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        text: "construction"
        color: Theme.warn
        size: Theme.menuIconSize + 4
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
          text: "Danbooru is down for maintenance"
          color: Theme.text
          font.family: Theme.labelFont
          font.pixelSize: Theme.menuTitleSize
        }

        Text {
          text: "Checking again every 30 seconds"
          color: Theme.textVariant
          font.family: Theme.labelFont
          font.pixelSize: Theme.menuSubtitleSize
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
        tint: Theme.tertiary
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Searching Danbooru…"
        color: Theme.text
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuTitleSize
      }
    }
  }

  Text {
    width: parent.width
    height: 56
    visible: !Danbooru.down && (Danbooru.phase === "error" || (Danbooru.phase === "results" && Danbooru.results.length === 0))
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    wrapMode: Text.WordWrap
    text: Danbooru.phase === "error" ? Danbooru.error : "Nothing found"
    color: Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuTitleSize
  }

  GridView {
    id: grid

    readonly property int columns: 3

    width: parent.width
    height: Math.min(contentHeight, root.gridMaxHeight)
    visible: !Danbooru.down && Danbooru.phase === "results" && Danbooru.results.length > 0
    clip: true
    cellWidth: width / columns
    cellHeight: Theme.thumbHeight + 6
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    model: ScriptModel {
      values: Danbooru.results
    }
    onAtYEndChanged: {
      if (atYEnd && contentHeight > height)
        Danbooru.loadMore();
    }

    footer: Item {
      width: grid.width
      height: Danbooru.loadingMore ? 40 : 0

      Spinner {
        anchors.centerIn: parent
        visible: Danbooru.loadingMore
        tint: Theme.tertiary
      }
    }

    delegate: ImageTile {
      required property var modelData

      width: grid.cellWidth
      height: grid.cellHeight
      source: modelData.thumb
      resolution: modelData.resolution
      busy: Danbooru.isDownloading(modelData)
      checked: Danbooru.isSaved(modelData)
      onClicked: Danbooru.save(modelData)
    }
  }
}
