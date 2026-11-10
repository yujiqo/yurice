import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  readonly property var minuteSteps: [0, 1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120]

  spacing: 14

  function formatMinutes(minutes) {
    if (minutes <= 0)
      return "Never";
    if (minutes < 60)
      return minutes + " min";
    const hours = Math.floor(minutes / 60);
    const rest = minutes % 60;
    return rest > 0 ? `${hours} h ${rest} min` : `${hours} h`;
  }

  function stepMinutes(current, direction) {
    const steps = minuteSteps;
    if (direction > 0) {
      const next = steps.find(s => s > current);
      return next ?? steps[steps.length - 1];
    }
    const lower = steps.filter(s => s < current);
    return lower.length > 0 ? lower[lower.length - 1] : steps[0];
  }

  component Group: Column {
    id: group

    property string title: ""
    default property alias rows: card.data

    width: parent.width
    spacing: 2

    Text {
      leftPadding: 8
      bottomPadding: 4
      text: group.title.toUpperCase()
      color: Theme.clock
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuSubtitleSize - 2
      font.letterSpacing: 1
      font.bold: true
    }

    Rectangle {
      width: parent.width
      height: card.implicitHeight + 8
      radius: Theme.menuItemRadius
      color: Theme.surfaceContainer

      Column {
        id: card
        y: 4
        width: parent.width
      }
    }
  }

  component DurationRow: InfoRow {
    id: row

    property string key: ""
    readonly property int minutes: Settings[key]

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
        opacity: row.minutes > 0 ? 1 : 0.4
        onClicked: Settings.set(row.key, root.stepMinutes(row.minutes, -1))
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 64
        horizontalAlignment: Text.AlignHCenter
        text: root.formatMinutes(row.minutes)
        color: Theme.text
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuSubtitleSize + 1
      }

      IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "add"
        opacity: row.minutes < root.minuteSteps[root.minuteSteps.length - 1] ? 1 : 0.4
        onClicked: Settings.set(row.key, root.stepMinutes(row.minutes, 1))
      }
    }
  }

  component SwitchRow: InfoRow {
    id: row

    property string key: ""

    width: parent.width
    value: ""

    Switch {
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      checked: Settings[row.key]
      onToggled: Settings.set(row.key, !Settings[row.key])
    }
  }

  Group {
    title: "Idle"

    DurationRow {
      icon: "monitor"
      label: "Screens off"
      key: "idleScreenOff"
    }

    DurationRow {
      icon: "desktop_access_disabled"
      label: "Locked: screens off"
      key: "idleLockedScreenOff"
    }

    DurationRow {
      icon: "lock_clock"
      label: "Lock"
      key: "idleLock"
    }

    DurationRow {
      icon: "mode_standby"
      label: "Locked: suspend"
      key: "idleSuspend"
    }
  }
}
