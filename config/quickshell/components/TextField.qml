pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Rectangle {
  id: root

  property alias text: input.text
  property alias inputActiveFocus: input.activeFocus
  property string placeholder: ""
  property real placeholderOpacity: 1
  property string leadingIcon: ""
  property string hint: ""
  property string tag: ""
  property bool clearable: false
  property bool escapeLeaves: false
  default property alias trailing: trailingRow.data

  signal accepted(string text)
  signal canceled
  signal navigate(int delta)
  signal keyPressed(var event)

  function focusInput() {
    input.forceActiveFocus();
  }

  function blur() {
    input.focus = false;
  }

  function keyActivate() {
    focusInput();
  }

  activeFocusOnTab: escapeLeaves
  implicitHeight: 46
  radius: Theme.menuItemRadius
  color: Theme.surfaceContainerHigh
  border.width: 2
  border.color: input.activeFocus ? Theme.primary : root.activeFocus ? Theme.text : "transparent"

  Behavior on border.color {
    ColorAnimation {
      duration: Theme.animHover
    }
  }

  Icon {
    id: lead
    anchors.left: parent.left
    anchors.leftMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    visible: root.leadingIcon !== ""
    text: root.leadingIcon
    color: input.activeFocus ? Theme.primary : Theme.textVariant
    size: Theme.menuIconSize
  }

  Text {
    anchors.fill: input
    verticalAlignment: Text.AlignVCenter
    text: root.placeholder
    visible: input.text === ""
    opacity: root.placeholderOpacity
    color: Theme.textVariant
    elide: Text.ElideRight
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuTitleSize
  }

  TextInput {
    id: input
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: lead.visible ? lead.right : parent.left
    anchors.leftMargin: lead.visible ? 10 : 14
    anchors.right: trailingRow.left
    anchors.rightMargin: 8
    verticalAlignment: TextInput.AlignVCenter
    color: Theme.text
    selectionColor: Theme.primary
    selectedTextColor: Theme.textOnPrimary
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuTitleSize
    clip: true
    activeFocusOnTab: false
    onAccepted: root.accepted(text)
    Keys.onPressed: event => {
      root.keyPressed(event);
      if (event.accepted)
        return;
      if (root.escapeLeaves) {
        if (event.key === Qt.Key_Escape) {
          root.forceActiveFocus();
          event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
          root.forceActiveFocus();
        }
        return;
      }
      if (event.key === Qt.Key_Escape) {
        root.canceled();
      } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
        root.navigate(1);
        event.accepted = true;
      } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
        root.navigate(-1);
        event.accepted = true;
      }
    }
  }

  Row {
    id: trailingRow
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    Item {
      id: tagSlot

      readonly property bool shown: root.tag !== ""
      property string shownText

      Component.onCompleted: shownText = root.tag

      anchors.verticalCenter: parent.verticalCenter
      width: shown ? tagLabel.implicitWidth : 0
      height: tagLabel.implicitHeight
      visible: width > 0
      clip: true
      opacity: shown ? 1 : 0

      Connections {
        target: root
        function onTagChanged() {
          if (root.tag !== "")
            tagSlot.shownText = root.tag;
        }
      }

      Behavior on width {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animColor
        }
      }

      Text {
        id: tagLabel
        rightPadding: 6
        text: root.hint !== "" ? `${tagSlot.shownText} ·` : tagSlot.shownText
        color: Theme.textVariant
        opacity: 0.7
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuSubtitleSize
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.hint !== ""
      rightPadding: 6
      text: root.hint
      color: Theme.textVariant
      opacity: 0.7
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuSubtitleSize
    }

    IconButton {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.clearable && input.text !== ""
      implicitWidth: 28
      implicitHeight: 28
      icon: "close"
      onClicked: {
        input.clear();
        input.forceActiveFocus();
      }
    }
  }
}
