pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  property bool showFilters: false
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

      Item {
        width: parent.width
        height: field.implicitHeight

        TextField {
          id: field
          anchors.left: parent.left
          anchors.right: tune.left
          anchors.rightMargin: 6
          anchors.verticalCenter: parent.verticalCenter
          leadingIcon: "sell"
          clearable: true
          placeholder: "Tags (e.g. scenery sky)"
          escapeLeaves: true
          hint: {
            const left = Danbooru.tagsLeft(field.text);
            const count = left < 0 ? "too many tags" : left === 1 ? "1 tag left" : `${left} tags left`;
            return Danbooru.safeOnly ? `SFW · ${count}` : count;
          }
          onAccepted: text => Danbooru.search(text)
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
              title: "Rating"
              visible: !WeebMode.hidesAdultFilters
              Chip {
                text: "SFW"
                selected: Danbooru.safeOnly
                onClicked: Danbooru.setSafeOnly(true)
              }
              Chip {
                text: "NSFW"
                selected: !Danbooru.safeOnly
                onClicked: Danbooru.setSafeOnly(false)
              }
            }

            FilterRow {
              title: "Key"
              Chip {
                icon: "key"
                text: Danbooru.hasApiKey ? "Change API key" : "Add API key"
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
                loginField.text = Danbooru.login;
                keyField.text = Danbooru.apiKey;
                loginField.focusInput();
              }
            }

            Column {
              width: parent.width
              spacing: 4

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
                width: parent.width
                wrapMode: Text.Wrap
                text: "Get it at danbooru.donmai.us/profile · Enter saves, empty removes"
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
    thumbFor: item => Danbooru.thumbFor(item)
    busyFor: item => Danbooru.isDownloading(item)
    checkedFor: item => Danbooru.isSaved(item)
    onActivated: item => Danbooru.save(item)
  }
}
