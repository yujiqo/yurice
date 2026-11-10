pragma ComponentBehavior: Bound
import QtQuick
import qs.components
import qs.services

Column {
  id: root

  spacing: 8

  component TimeRow: StepperRow {
    property string name: ""

    valueText: ThemeMode.formatMinutes(ThemeMode[name])
    valueWidth: Clock.clock24h ? 44 : 70
    valueOpacity: Clock.fade
    onDecreased: ThemeMode.adjust(name, -30)
    onIncreased: ThemeMode.adjust(name, 30)
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
