pragma ComponentBehavior: Bound
import QtQuick
import qs.components
import qs.services

IconIsland {
  id: root

  panels: ({
      weeb: weebPanel
    })
  panelWidth: 340
  icon: WeebMode.icon
  label: WeebMode.label
  smoothLabel: true
  onClicked: mouse => mouse.button === Qt.RightButton ? WeebMode.toggle() : request("weeb")

  Component {
    id: weebPanel

    WeebPanel {}
  }
}
