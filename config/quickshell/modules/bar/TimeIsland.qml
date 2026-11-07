import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  open: current === "calendar"
  panel: current === "calendar" ? calendarPanel : null
  panelWidth: 320
  spacing: 0
  clickable: true
  onClicked: request("calendar")

  Component {
    id: calendarPanel

    CalendarPanel {}
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
