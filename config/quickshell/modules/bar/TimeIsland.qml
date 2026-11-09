import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  open: current === "calendar" || current === "power"
  panel: current === "power" ? powerPanel : current === "calendar" ? calendarPanel : null
  panelIndex: current === "power" ? 1 : 0
  panelWidth: shownPanel === powerPanel ? 440 : 320
  Behavior on panelWidth {
    NumberAnimation {
      duration: Theme.animMove
      easing.type: Easing.OutCubic
    }
  }
  spacing: 0
  clickable: true
  onClicked: request("calendar")

  Component {
    id: calendarPanel

    CalendarPanel {}
  }

  Component {
    id: powerPanel

    PowerPanel {}
  }

  Text {
    height: Theme.pillHeight
    verticalAlignment: Text.AlignVCenter
    text: Qt.formatDateTime(Clock.date, "HH:mm")
    color: Theme.text
    font.family: Theme.labelFont
    font.pixelSize: Theme.labelSize
  }

  Reveal {
    shown: root.expanded
    leading: Theme.pillSegmentGap

    Text {
      text: Qt.formatDateTime(Clock.date, "ddd dd MMM")
      color: Theme.clock
      font.family: Theme.labelFont
      font.pixelSize: Theme.labelSize
    }
  }
}
