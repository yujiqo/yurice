import QtQuick
import Quickshell.Io
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  readonly property var minuteSteps: [0, 1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120]
  property var shownResults: []

  Connections {
    target: Weather
    function onSearchResultsChanged() {
      if (Weather.searchResults.length > 0)
        root.shownResults = Weather.searchResults;
    }
  }

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

  component PathRow: Column {
    id: row

    property string key: ""
    property string icon: ""
    property string label: ""
    property string path: ""
    property string error: ""
    property string pending: ""
    property bool saved: false
    property string message: ""
    property bool messageIsError: false

    onErrorChanged: {
      if (error === "")
        return;
      message = error;
      messageIsError = true;
    }

    onSavedChanged: {
      if (!saved)
        return;
      message = "Saved";
      messageIsError = false;
    }

    width: parent.width
    bottomPadding: 6

    function revert() {
      field.text = Settings.displayPath(path);
      error = "";
    }

    function confirm() {
      field.blur();
      revert();
      saved = true;
      savedTimer.restart();
    }

    function submit(text) {
      const value = text.trim();
      saved = false;
      if (value === "") {
        Settings.set(key, undefined);
        Qt.callLater(confirm);
        return;
      }
      if (!value.startsWith("/") && !value.startsWith("~")) {
        error = "Use an absolute path or one starting with ~";
        return;
      }
      pending = value;
      check.running = true;
    }

    onPathChanged: revert()
    Component.onCompleted: revert()

    Process {
      id: check
      command: ["sh", "-c", 'mkdir -p "$1" && test -d "$1" && test -w "$1"', "sh", Settings.expandPath(row.pending)]
      onExited: code => {
        if (code !== 0) {
          row.error = "Can't create or write to this folder";
          return;
        }
        const display = Settings.displayPath(Settings.expandPath(row.pending).replace(/\/+$/, "") || "/");
        Settings.set(row.key, display);
        row.confirm();
      }
    }

    Timer {
      id: savedTimer
      interval: 2500
      onTriggered: row.saved = false
    }

    InfoRow {
      width: parent.width
      icon: row.icon
      label: row.label
      value: row.message
      valueColor: row.messageIsError ? Theme.error : Theme.primary
      valueOpacity: row.error !== "" || row.saved ? 1 : 0

      Behavior on valueOpacity {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Easing.InOutQuad
        }
      }
    }

    TextField {
      id: field
      x: 8
      width: parent.width - 16
      implicitHeight: 40
      escapeLeaves: true
      hint: inputActiveFocus ? "Enter" : ""
      onAccepted: text => row.submit(text)
      onInputActiveFocusChanged: {
        if (!inputActiveFocus && !check.running)
          row.revert();
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

  Group {
    title: "Clock"

    SwitchRow {
      icon: "schedule"
      label: "24-hour time"
      key: "clock24h"
    }

    SwitchRow {
      icon: "timer"
      label: "Show seconds"
      key: "clockSeconds"
    }
  }

  Group {
    title: "Weather"

    SwitchRow {
      icon: "thermostat"
      label: "Fahrenheit"
      key: "weatherFahrenheit"
    }

    InfoRow {
      width: parent.width
      icon: "location_on"
      label: "Location"
      value: Weather.cityIsManual ? Weather.city : Weather.city !== "" ? "Auto · " + Weather.city : "Auto"
      valueOpacity: Weather.fade
    }

    Column {
      width: parent.width
      spacing: 0
      bottomPadding: 6

      TextField {
        id: citySearch
        x: 8
        width: parent.width - 16
        implicitHeight: 40
        leadingIcon: "search"
        placeholder: "Search city"
        escapeLeaves: true
        clearable: true
        onTextChanged: searchDelay.restart()
        onAccepted: {
          searchDelay.stop();
          Weather.search(text);
        }
        Component.onDestruction: Weather.clearSearch()
      }

      Timer {
        id: searchDelay
        interval: 400
        onTriggered: Weather.search(citySearch.text)
      }

      Collapse {
        width: parent.width
        shown: Weather.searchResults.length > 0 || (Weather.searching && citySearch.text.trim().length >= 2)
        leading: 6
        onVisibleChanged: {
          if (!visible)
            root.shownResults = [];
        }

        Column {
          width: parent.width
          spacing: 2

          Text {
            visible: Weather.searching && root.shownResults.length === 0
            leftPadding: 16
            topPadding: 6
            bottomPadding: 6
            text: "Searching…"
            color: Theme.textVariant
            font.family: Theme.labelFont
            font.pixelSize: Theme.menuSubtitleSize
          }

          Repeater {
            model: root.shownResults

            MenuItem {
              required property var modelData

              x: 4
              width: parent.width - 8
              icon: "location_on"
              title: modelData.name
              subtitle: modelData.region
              onClicked: {
                Settings.set("weatherLocation", {
                  name: modelData.name,
                  latitude: modelData.latitude,
                  longitude: modelData.longitude
                });
                citySearch.text = "";
                citySearch.blur();
                Weather.clearSearch();
              }
            }
          }
        }
      }

      Collapse {
        width: parent.width
        shown: Weather.manual !== null
        leading: 2

        MenuItem {
          x: 4
          width: parent.width - 8
          icon: "my_location"
          title: "Use automatic location"
          onClicked: Settings.set("weatherLocation", undefined)
        }
      }
    }
  }

  Group {
    title: "Folders"

    PathRow {
      icon: "wallpaper"
      label: "Wallpapers"
      key: "wallpaperDirectory"
      path: Settings.wallpaperDirectory
    }

    PathRow {
      icon: "download"
      label: "Danbooru downloads"
      key: "danbooruDirectory"
      path: Settings.danbooruDirectory
    }

    PathRow {
      icon: "screenshot_monitor"
      label: "Screenshots"
      key: "screenshotDirectory"
      path: Settings.screenshotDirectory
    }
  }
}
