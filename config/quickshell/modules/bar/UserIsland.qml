import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  readonly property real avatarSize: Theme.pillHeight - 6

  open: current === "user"
  panel: current === "user" ? userPanel : null
  panelWidth: AvatarEditor.active ? 560 : 380
  Behavior on panelWidth {
    NumberAnimation {
      duration: Theme.animMove
      easing.type: Easing.OutCubic
    }
  }
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

    Avatar {
      anchors.centerIn: parent
      width: root.avatarSize
      height: root.avatarSize
      path: SessionLock.avatar
      iconSize: Theme.iconSize - 2
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
