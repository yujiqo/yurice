import QtQuick
import qs.theme
import qs.components
import qs.services

Item {
  id: root

  readonly property bool keepOpen: true
  readonly property var actions: [
    {
      id: "poweroff",
      name: "Power off",
      icon: "power_settings_new",
      confirm: true
    },
    {
      id: "reboot",
      name: "Reboot",
      icon: "restart_alt",
      confirm: true
    },
    {
      id: "suspend",
      name: "Suspend",
      icon: "bedtime",
      confirm: false
    }
  ]
  property int selected: 2
  property string armed: ""

  implicitHeight: 104
  focus: true

  Component.onCompleted: forceActiveFocus()

  function activate(index) {
    const action = actions[index];
    selected = index;
    if (action.confirm && armed !== action.id) {
      armed = action.id;
      disarm.restart();
      return;
    }
    armed = "";
    Session.run(action.id);
  }

  function move(delta) {
    selected = (selected + delta + actions.length) % actions.length;
    if (armed !== "" && armed !== actions[selected].id)
      armed = "";
  }

  Keys.onLeftPressed: move(-1)
  Keys.onRightPressed: move(1)
  Keys.onTabPressed: move(1)
  Keys.onBacktabPressed: move(-1)
  Keys.onReturnPressed: activate(selected)
  Keys.onEnterPressed: activate(selected)
  Keys.onSpacePressed: activate(selected)

  Timer {
    id: disarm
    interval: 3000
    onTriggered: root.armed = ""
  }

  Row {
    anchors.fill: parent
    anchors.bottomMargin: 4
    spacing: 8

    Repeater {
      model: root.actions

      Rectangle {
        id: button

        required property var modelData
        required property int index
        readonly property bool isArmed: root.armed === modelData.id
        readonly property bool isSelected: root.selected === index

        width: (parent.width - 16) / 3
        height: parent.height
        radius: Theme.menuItemRadius
        color: isArmed ? Theme.error : isSelected ? Theme.primary : Theme.surfaceContainer
        scale: mouse.pressed ? 0.95 : 1

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

        Column {
          anchors.centerIn: parent
          spacing: 8

          Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: button.modelData.icon
            size: 30
            color: button.isArmed ? Theme.surface : button.isSelected ? Theme.textOnPrimary : Theme.text
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: button.isArmed ? "Press again" : button.modelData.name
            color: button.isArmed ? Theme.surface : button.isSelected ? Theme.textOnPrimary : Theme.text
            font.family: Theme.labelFont
            font.pixelSize: Theme.menuSubtitleSize
          }
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.move(button.index - root.selected)
          onClicked: root.activate(button.index)
        }
      }
    }
  }
}
