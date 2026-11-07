import QtQuick
import qs.theme

Rectangle {
  id: root

  property alias text: input.text
  property string placeholder: "Password"
  property bool reveal: false

  signal accepted(string text)
  signal canceled

  function focusInput() {
    input.forceActiveFocus();
  }

  implicitHeight: 46
  radius: Theme.menuItemRadius
  color: Theme.surfaceContainerHigh
  border.width: 2
  border.color: input.activeFocus ? Theme.primary : "transparent"

  Behavior on border.color {
    ColorAnimation {
      duration: Theme.animHover
    }
  }

  Text {
    anchors.fill: input
    verticalAlignment: Text.AlignVCenter
    text: root.placeholder
    visible: input.text === ""
    color: Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuTitleSize
  }

  TextInput {
    id: input
    anchors.fill: parent
    anchors.leftMargin: 14
    anchors.rightMargin: 44
    verticalAlignment: TextInput.AlignVCenter
    echoMode: root.reveal ? TextInput.Normal : TextInput.Password
    color: Theme.text
    selectionColor: Theme.primary
    selectedTextColor: Theme.onPrimary
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuTitleSize
    clip: true
    onAccepted: root.accepted(text)
    Keys.onEscapePressed: root.canceled()
  }

  IconButton {
    anchors.right: parent.right
    anchors.rightMargin: 5
    anchors.verticalCenter: parent.verticalCenter
    icon: root.reveal ? "visibility_off" : "visibility"
    onClicked: root.reveal = !root.reveal
  }
}
