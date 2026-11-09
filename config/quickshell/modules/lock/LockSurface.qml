import QtQuick
import QtQuick.Effects
import qs.theme
import qs.components

Item {
  id: root

  property string wallpaper: ""
  property size imageSize: Qt.size(0, 0)
  property url snapshot
  property real reveal: 1
  property bool interactive: true
  property bool primary: true
  property string avatar: ""
  property string userName: ""
  property bool promptOpen: false
  property bool busy: false
  property string error: ""
  property bool firmwareAvailable: false
  property string armed: ""
  property string placeholder: "Password"
  property bool canSwitchUser: false
  readonly property real lockScale: 1 + Theme.lockZoom * (1 - reveal)

  readonly property var powerActions: {
    const list = [
      {
        id: "reboot",
        icon: "restart_alt",
        label: "Restart"
      },
      {
        id: "poweroff",
        icon: "power_settings_new",
        label: "Power off"
      }
    ];
    if (firmwareAvailable)
      list.unshift({
        id: "firmware",
        icon: "memory",
        label: "Firmware setup"
      });
    return list;
  }

  readonly property bool wallpaperReady: wallpaper === "" || wallpaperImage.status === Image.Ready || wallpaperImage.status === Image.Error

  signal ready
  signal promptRequested
  signal promptDismissed
  signal submitted(string password)
  signal powerRequested(string action)
  signal userSwitchRequested(int delta)

  Keys.onTabPressed: event => event.accepted = true
  Keys.onBacktabPressed: event => event.accepted = true
  Keys.onLeftPressed: {
    if (root.interactive && root.canSwitchUser)
      root.userSwitchRequested(-1);
  }
  Keys.onRightPressed: {
    if (root.interactive && root.canSwitchUser)
      root.userSwitchRequested(1);
  }
  Keys.onPressed: event => {
    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
      return;
    if (event.key !== Qt.Key_H && event.key !== Qt.Key_L)
      return;
    event.accepted = true;
    if (root.interactive && root.canSwitchUser)
      root.userSwitchRequested(event.key === Qt.Key_H ? -1 : 1);
  }
  Keys.onSpacePressed: {
    if (root.interactive)
      root.promptRequested();
  }

  function reportReady() {
    if (wallpaperReady && imageSize.width > 0)
      ready();
  }

  focus: true
  onWallpaperReadyChanged: reportReady()
  onImageSizeChanged: reportReady()
  Component.onCompleted: {
    forceActiveFocus();
    reportReady();
  }

  Keys.onReturnPressed: {
    if (root.interactive)
      root.promptRequested();
  }
  Keys.onEnterPressed: {
    if (root.interactive)
      root.promptRequested();
  }

  onPromptOpenChanged: {
    field.text = "";
    if (promptOpen && primary)
      field.focusInput();
    else
      root.forceActiveFocus();
  }
  onPrimaryChanged: {
    if (promptOpen && primary)
      field.focusInput();
    else
      root.forceActiveFocus();
  }
  onBusyChanged: {
    if (!busy && promptOpen && primary) {
      field.text = "";
      field.focusInput();
    }
  }

  function activatePower(action) {
    if (armed !== action) {
      armed = action;
      disarm.restart();
      return;
    }
    armed = "";
    root.powerRequested(action);
  }

  Timer {
    id: disarm
    interval: 3000
    onTriggered: root.armed = ""
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.surfaceContainerHigh
    opacity: root.reveal
    scale: root.lockScale
  }

  Image {
    id: wallpaperImage
    anchors.fill: parent
    source: root.imageSize.width > 0 ? Utility.fileUrl(root.wallpaper) : ""
    sourceSize: root.imageSize
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: true
    smooth: true
    opacity: root.reveal
    scale: root.lockScale
  }

  Image {
    id: snapshotImage
    anchors.fill: parent
    source: root.snapshot
    cache: false
    visible: false
  }

  MultiEffect {
    anchors.fill: parent
    source: snapshotImage
    visible: root.reveal < 1 && snapshotImage.status === Image.Ready
    blurEnabled: true
    blurMax: 64
    blur: root.reveal
    opacity: 1 - root.reveal
    scale: 1 - Theme.lockZoom * root.reveal
  }

  Item {
    anchors.fill: parent
    enabled: root.interactive
    opacity: root.reveal
    scale: root.lockScale

    MouseArea {
      anchors.fill: parent
      onClicked: root.promptRequested()
    }

    Column {
      anchors.centerIn: parent
      width: 340
      spacing: 14

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 128
        height: 128
        radius: width / 2
        color: Theme.surfaceContainerHigh

        RoundedImage {
          id: avatarImage
          anchors.fill: parent
          radius: width / 2
          source: Utility.fileUrl(root.avatar)
          sourceSize: Qt.size(256, 256)
        }

        Icon {
          anchors.centerIn: parent
          visible: avatarImage.status !== Image.Ready
          text: "person"
          color: Theme.textVariant
          size: 64
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.promptRequested()
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6

        IconButton {
          anchors.verticalCenter: parent.verticalCenter
          visible: root.canSwitchUser
          activeFocusOnTab: false
          color: Theme.surface
          icon: "chevron_left"
          onClicked: root.userSwitchRequested(-1)
        }

        Rectangle {
          width: userLabel.implicitWidth + 32
          height: 40
          radius: height / 2
          color: Theme.surface

          Label {
            id: userLabel
            anchors.centerIn: parent
            text: root.userName
            pixelSize: Theme.menuTitleSize + 3
          }
        }

        IconButton {
          anchors.verticalCenter: parent.verticalCenter
          visible: root.canSwitchUser
          activeFocusOnTab: false
          color: Theme.surface
          icon: "chevron_right"
          onClicked: root.userSwitchRequested(1)
        }
      }

      Collapse {
        width: parent.width
        shown: root.promptOpen && root.primary

        PasswordField {
          id: field
          width: parent.width
          placeholder: root.placeholder
          onAccepted: text => root.submitted(text)
          onCanceled: root.promptDismissed()
        }
      }

      Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: 34
        visible: root.primary

        Rectangle {
          anchors.centerIn: parent
          visible: root.busy || root.error !== ""
          width: root.busy ? height : errorLabel.implicitWidth + 28
          height: parent.height
          radius: height / 2
          color: Theme.surface

          Spinner {
            anchors.centerIn: parent
            visible: root.busy
            tint: Theme.text
          }

          Label {
            id: errorLabel
            anchors.centerIn: parent
            visible: !root.busy
            text: root.error
            pixelSize: Theme.menuTitleSize
          }
        }
      }
    }

    Row {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: 24
      spacing: 8

      Repeater {
        model: root.powerActions

        Rectangle {
          id: powerButton

          required property var modelData
          readonly property bool isArmed: root.armed === modelData.id

          anchors.verticalCenter: parent.verticalCenter
          width: buttonRow.implicitWidth + 24
          height: 44
          radius: height / 2
          color: isArmed ? Theme.error : buttonMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surface
          scale: buttonMouse.pressed ? 0.95 : 1

          Behavior on color {
            ColorAnimation {
              duration: Theme.animHover
            }
          }
          Behavior on scale {
            NumberAnimation {
              duration: Theme.animPress
            }
          }

          Row {
            id: buttonRow
            anchors.centerIn: parent
            height: parent.height

            Icon {
              anchors.verticalCenter: parent.verticalCenter
              text: powerButton.modelData.icon
              color: powerButton.isArmed ? Theme.surface : Theme.text
              size: Theme.menuIconSize
            }

            Reveal {
              anchors.verticalCenter: parent.verticalCenter
              shown: powerButton.isArmed || buttonMouse.containsMouse
              leading: 8

              Label {
                text: powerButton.isArmed ? "Press again" : powerButton.modelData.label
                color: powerButton.isArmed ? Theme.surface : Theme.text
                pixelSize: Theme.menuSubtitleSize + 1
              }
            }
          }

          MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activatePower(powerButton.modelData.id)
          }
        }
      }
    }
  }
}
