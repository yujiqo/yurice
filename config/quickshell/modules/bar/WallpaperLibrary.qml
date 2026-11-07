import QtQuick
import Quickshell
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  property real maxHeight: Theme.dropdownMaxHeight - Theme.panelPadding * 2
  property string selected: ""
  readonly property bool keepOpen: false

  Component.onCompleted: forceActiveFocus()

  Keys.onEscapePressed: event => {
    if (selected !== "")
      selected = "";
    else
      event.accepted = false;
  }

  Text {
    width: parent.width
    height: 56
    visible: Wallpapers.wallpapers.length === 0
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: "No wallpapers in ~/Pictures/Wallpapers"
    color: Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuTitleSize
  }

  GridView {
    id: grid

    readonly property int columns: 3

    width: parent.width
    height: Math.min(contentHeight, root.maxHeight)
    visible: Wallpapers.wallpapers.length > 0
    clip: true
    cellWidth: width / columns
    cellHeight: Theme.thumbHeight + 6
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    model: ScriptModel {
      values: Wallpapers.wallpapers
    }

    delegate: ImageTile {
      id: tile

      required property string modelData
      readonly property bool active: root.selected === modelData

      width: grid.cellWidth
      height: grid.cellHeight
      source: "file://" + modelData
      resolution: Wallpapers.resolutionOf(modelData)
      resolutionColor: Wallpapers.isLowRes(modelData) ? Theme.warn : Theme.text
      showResolution: hovered && !active
      checked: Wallpapers.current === modelData
      onClicked: root.selected = active ? "" : modelData

      Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.alpha(Theme.surface, 0.72)
        opacity: tile.active ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
          NumberAnimation {
            duration: Theme.animHover
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: root.selected = ""
        }

        Column {
          anchors.centerIn: parent
          spacing: 6

          Chip {
            width: tile.frame.width - 24
            icon: "auto_awesome"
            text: "Upscale"
            onClicked: root.selected = ""
          }

          Chip {
            width: tile.frame.width - 24
            icon: "delete"
            text: "Delete"
            onClicked: root.selected = ""
          }
        }
      }
    }
  }
}
