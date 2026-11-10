import QtQuick
import qs.theme
import qs.components
import qs.services

Item {
  id: root

  property bool settingsOpen: false

  implicitHeight: Math.min(content.implicitHeight, Theme.userPanelMaxHeight - Theme.pillHeight - Theme.panelPadding * 2)

  Component.onCompleted: SystemInfo.refresh()

  Flickable {
    id: flick
    anchors.fill: parent
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: content
      width: flick.width
      spacing: 8

      Item {
        width: parent.width
        height: 72

        Avatar {
          id: hero
          anchors.left: parent.left
          anchors.leftMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          width: 56
          height: 56
          path: SessionLock.avatar
          iconSize: 30
        }

        Column {
          anchors.left: hero.right
          anchors.leftMargin: 14
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 4

          Label {
            width: parent.width
            text: SessionLock.userName
            color: Theme.text
            pixelSize: 24
          }

          Label {
            width: parent.width
            text: SystemInfo.hostname !== "" ? SessionLock.userName + "@" + SystemInfo.hostname : ""
            color: Theme.textVariant
            pixelSize: Theme.menuSubtitleSize
          }
        }
      }

      Rectangle {
        width: parent.width
        height: details.implicitHeight + 8
        radius: Theme.menuItemRadius
        color: Theme.surfaceContainer

        Column {
          id: details
          y: 4
          width: parent.width

          InfoRow {
            width: parent.width
            icon: "schedule"
            label: "Uptime"
            value: SystemInfo.loaded ? SystemInfo.uptime : "—"
          }

          InfoRow {
            width: parent.width
            icon: "dns"
            label: "Hostname"
            value: SystemInfo.hostname || "—"
          }

          InfoRow {
            width: parent.width
            icon: "memory"
            label: "Kernel"
            value: SystemInfo.kernel || "—"
          }

          InfoRow {
            width: parent.width
            icon: "ac_unit"
            label: "NixOS"
            value: SystemInfo.version || "—"
          }

          InfoRow {
            width: parent.width
            icon: "history"
            label: "Generation"
            value: SystemInfo.generation > 0 ? `${SystemInfo.generation} · ${Qt.formatDateTime(SystemInfo.generationDate, "dd MMM yyyy")}` : "—"
          }
        }
      }

      MenuItem {
        width: parent.width
        icon: "settings"
        title: "Settings"
        onClicked: root.settingsOpen = !root.settingsOpen

        Icon {
          anchors.verticalCenter: parent.verticalCenter
          text: "expand_more"
          color: Theme.textVariant
          size: Theme.menuIconSize
          rotation: root.settingsOpen ? 180 : 0

          Behavior on rotation {
            NumberAnimation {
              duration: Theme.animMove
              easing.type: Theme.easeOut
            }
          }
        }
      }

      Collapse {
        width: parent.width
        shown: root.settingsOpen

        UserSettings {
          width: parent.width
          bottomPadding: 4
        }
      }
    }
  }
}
