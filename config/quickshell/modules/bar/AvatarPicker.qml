pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  readonly property bool cropping: AvatarEditor.file !== ""

  spacing: 10

  Item {
    width: parent.width
    height: 48

    IconButton {
      id: backButton
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      icon: "arrow_back"
      onClicked: root.cropping && !AvatarEditor.saving ? AvatarEditor.back() : AvatarEditor.close()
    }

    Avatar {
      id: current
      anchors.left: backButton.right
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      width: 36
      height: 36
      path: AvatarEditor.target
      iconSize: 20
    }

    Column {
      anchors.left: current.right
      anchors.leftMargin: 12
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Label {
        width: parent.width
        text: AvatarEditor.mode === "normie" ? "Normie picture" : "Weeb picture"
        pixelSize: Theme.menuTitleSize
      }

      Label {
        width: parent.width
        text: root.cropping ? Paths.baseName(AvatarEditor.file) : "Pick an image"
        color: Theme.textVariant
        pixelSize: Theme.menuSubtitleSize
      }
    }
  }

  Item {
    width: parent.width
    height: root.cropping ? cropper.implicitHeight : browser.implicitHeight

    AvatarBrowser {
      id: browser
      width: parent.width
      opacity: root.cropping ? 0 : 1
      visible: opacity > 0
      enabled: !root.cropping

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Easing.InOutQuad
        }
      }
    }

    AvatarCropper {
      id: cropper
      width: parent.width
      opacity: root.cropping ? 1 : 0
      visible: opacity > 0
      enabled: root.cropping

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Easing.InOutQuad
        }
      }
    }
  }
}
