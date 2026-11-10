pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  spacing: 8

  component TimeRow: InfoRow {
    id: row

    property string name: ""
    readonly property int step: 30

    width: parent.width
    value: ""

    Row {
      anchors.right: parent.right
      anchors.rightMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "remove"
        onClicked: ThemeMode.adjust(row.name, -row.step)
      }

      Label {
        anchors.verticalCenter: parent.verticalCenter
        width: Clock.clock24h ? 44 : 70
        opacity: Clock.fade
        text: ThemeMode.formatMinutes(ThemeMode[row.name])

        Behavior on width {
          NumberAnimation {
            duration: Theme.animMove
            easing.type: Theme.easeOut
          }
        }
        pixelSize: Theme.menuSubtitleSize + 1
      }

      IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "add"
        onClicked: ThemeMode.adjust(row.name, row.step)
      }
    }
  }

  Item {
    width: parent.width
    height: 64

    Icon {
      id: heroIcon
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: ThemeMode.icon
      color: Theme.primary
      size: 44
    }

    Column {
      anchors.left: heroIcon.right
      anchors.leftMargin: 14
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Label {
        text: ThemeMode.label
        pixelSize: 30
      }

      Label {
        width: parent.width
        text: ThemeMode.status
        color: Theme.textVariant
        pixelSize: Theme.menuSubtitleSize
      }
    }
  }

  Rectangle {
    width: parent.width
    height: settings.implicitHeight + 8
    radius: Theme.menuItemRadius
    color: Theme.surfaceContainer

    Column {
      id: settings
      y: 4
      width: parent.width

      InfoRow {
        width: parent.width
        icon: "schedule"
        label: "Automatic"
        value: ""

        Switch {
          anchors.right: parent.right
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          checked: ThemeMode.auto
          onToggled: ThemeMode.setAuto(!ThemeMode.auto)
        }
      }

      TimeRow {
        visible: ThemeMode.auto
        icon: "light_mode"
        label: "Light from"
        name: "lightStart"
      }

      TimeRow {
        visible: ThemeMode.auto
        icon: "dark_mode"
        label: "Dark from"
        name: "lightEnd"
      }
    }
  }

  ChoiceGroup {
    width: parent.width
    options: [
      {
        value: "light",
        icon: "light_mode",
        label: "Light"
      },
      {
        value: "dark",
        icon: "dark_mode",
        label: "Dark"
      }
    ]
    current: ThemeMode.mode
    onSelected: value => ThemeMode.set(value)
  }
}
