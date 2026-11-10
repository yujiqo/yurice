import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  readonly property real avatarSize: Theme.pillHeight - 6

  open: current === "user"
  panel: current === "user" ? userPanel : null
  panelWidth: 380
  padding: (Theme.pillHeight - avatarSize) / 2
  spacing: 0
  clickable: true
  onClicked: request("user")

  Component {
    id: userPanel

    UserPanel {}
  }

  Item {
    width: root.avatarSize
    height: Theme.pillHeight

    Rectangle {
      anchors.centerIn: parent
      width: root.avatarSize
      height: root.avatarSize
      radius: width / 2
      color: Theme.surfaceContainer
      visible: avatar.status !== Image.Ready

      Icon {
        anchors.centerIn: parent
        text: "person"
        color: Theme.primary
        size: Theme.iconSize - 2
      }
    }

    RoundedImage {
      id: avatar
      anchors.centerIn: parent
      width: root.avatarSize
      height: root.avatarSize
      radius: width / 2
      source: Utility.fileUrl(SessionLock.avatar)
      sourceSize: Qt.size(root.avatarSize * 2, root.avatarSize * 2)
    }
  }

  Reveal {
    shown: root.expanded
    leading: Theme.pillIconGap + 2

    Row {
      Label {
        text: SessionLock.userName
      }

      Item {
        width: Theme.pillPadding - root.padding
        height: 1
      }
    }
  }
}
