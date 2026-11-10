pragma ComponentBehavior: Bound
import QtQuick
import qs.components
import qs.services

IconIsland {
  id: root

  panels: ({
      theme: themePanel
    })
  panelWidth: 340
  icon: "contrast"
  label: ThemeMode.label
  onClicked: mouse => mouse.button === Qt.RightButton ? ThemeMode.toggle() : request("theme")

  Component {
    id: themePanel

    ThemePanel {}
  }
}
