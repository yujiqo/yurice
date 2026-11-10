pragma ComponentBehavior: Bound
import QtQuick
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

  SearchResults {
    feed: Danbooru
    label: "Danbooru"
    blocked: Danbooru.down
    maxHeight: root.gridMaxHeight
    busyFor: item => Danbooru.isDownloading(item)
    checkedFor: item => Danbooru.isSaved(item)
    onActivated: item => Danbooru.save(item)
  }
}
