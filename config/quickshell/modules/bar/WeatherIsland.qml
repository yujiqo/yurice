pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  open: current === "weather"
  panel: current === "weather" ? weatherPanel : null
  panelWidth: Theme.panelWidth
  spacing: 0
  clickable: true
  onClicked: request("weather")
  width: implicitWidth * Math.max(0, appear.value)
  opacity: appear.progress
  visible: appear.value > 0.01

  Spring {
    id: appear
    target: Weather.ready ? 1 : 0
    Component.onCompleted: value = target
  }

  Component {
    id: weatherPanel

    WeatherPanel {}
  }

  Icon {
    anchors.verticalCenter: parent.verticalCenter
    text: "filter_drama"
    color: Theme.weather
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    leftPadding: Theme.pillIconGap
    text: Math.round(Weather.temperature) + "°"
    opacity: Weather.fade
    color: Theme.text
    font.family: Theme.labelFont
    font.pixelSize: Theme.labelSize
  }

  Reveal {
    shown: root.expanded
    leading: Theme.pillSegmentGap

    Label {
      text: Weather.current.text
      opacity: Weather.fade
      color: Theme.weather
    }
  }
}
