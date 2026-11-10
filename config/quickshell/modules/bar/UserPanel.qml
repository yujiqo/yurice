import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  spacing: 8

  Component.onCompleted: SystemInfo.refresh()

  Item {
    width: parent.width
    height: 72

    Item {
      id: hero
      anchors.left: parent.left
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      width: 56
      height: 56

      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.surfaceContainer
        visible: heroImage.status !== Image.Ready

        Icon {
          anchors.centerIn: parent
          text: "person"
          color: Theme.primary
          size: 30
        }
      }

      RoundedImage {
        id: heroImage
        anchors.fill: parent
        radius: width / 2
        source: Utility.fileUrl(SessionLock.avatar)
        sourceSize: Qt.size(112, 112)
      }
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
}
