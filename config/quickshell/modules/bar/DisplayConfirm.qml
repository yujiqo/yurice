pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.components
import qs.services

PanelWindow {
  id: root

  required property ShellScreen modelData
  property string screenName: ""
  readonly property bool attached: !!modelData && (modelData.name ?? "") === screenName && Quickshell.screens.includes(modelData)
  readonly property bool shown: attached && Displays.confirming && Displays.confirmScreens.includes(screenName)

  Component.onCompleted: screenName = modelData?.name ?? ""

  screen: modelData
  visible: attached && (shown || card.opacity > 0)
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "yurice-display-confirm"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  implicitWidth: card.width + 40
  implicitHeight: card.height + 40
  color: "transparent"

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 380
    height: content.implicitHeight + 36
    radius: Theme.panelRadius
    color: Theme.surface
    border.width: 1
    border.color: Theme.divider
    opacity: root.shown ? 1 : 0
    scale: root.shown ? 1 : 0.92

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.animMove
        easing.type: Easing.InOutQuad
      }
    }

    Behavior on scale {
      NumberAnimation {
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
    }

    Column {
      id: content
      anchors.centerIn: parent
      width: parent.width - 36
      spacing: 14

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Icon {
          anchors.verticalCenter: parent.verticalCenter
          text: "monitor"
          color: Theme.primary
          size: 26
        }

        Label {
          anchors.verticalCenter: parent.verticalCenter
          text: "Keep these display settings?"
          pixelSize: Theme.menuTitleSize
        }
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: `Reverting in ${Math.max(0, Displays.countdown)} s`
        color: Theme.textVariant
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuSubtitleSize
      }

      Item {
        width: parent.width
        height: 4

        Rectangle {
          width: parent.width
          height: parent.height
          radius: height / 2
          color: Theme.surfaceContainerHighest
        }

        Rectangle {
          width: parent.width * Math.max(0, Displays.countdown) / Displays.confirmSeconds
          height: parent.height
          radius: height / 2
          color: Theme.primary

          Behavior on width {
            NumberAnimation {
              duration: 1000
            }
          }
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Chip {
          icon: "undo"
          text: "Revert"
          available: Displays.confirming
          onClicked: Displays.revert()
        }

        Chip {
          icon: "check"
          text: "Keep"
          selected: true
          available: Displays.confirming
          onClicked: Displays.keep()
        }
      }
    }
  }
}
