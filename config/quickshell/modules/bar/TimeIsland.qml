pragma ComponentBehavior: Bound
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

  Item {
    width: time.implicitWidth
    height: Theme.pillHeight

    Behavior on width {
      NumberAnimation {
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
    }

    Text {
      id: time
      height: parent.height
      verticalAlignment: Text.AlignVCenter
      text: Qt.formatDateTime(Clock.date, Clock.timeFormat)
      color: Theme.text
      opacity: Clock.fade
      font.family: Theme.labelFont
      font.pixelSize: Theme.labelSize
    }
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
