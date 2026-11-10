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

  PanelHeader {
    icon: ThemeMode.icon
    title: ThemeMode.label
    subtitle: ThemeMode.status
  }

  Card {
    SwitchRow {
      icon: "schedule"
      label: "Automatic"
      checked: ThemeMode.auto
      onToggled: ThemeMode.setAuto(!ThemeMode.auto)
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
