pragma ComponentBehavior: Bound
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
    text: Wallpapers.hideUnsafe ? "No safe wallpapers yet, mark some in weeb mode" : "No wallpapers in " + Paths.display(Wallpapers.directory)
    color: Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuTitleSize
  }

  GridView {
    id: grid

    readonly property int columns: 2

    width: parent.width
    height: Math.min(contentHeight, root.maxHeight)
    visible: Wallpapers.wallpapers.length > 0
    clip: true
    cellWidth: width / columns
    cellHeight: Theme.libraryThumbHeight
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    model: ScriptModel {
      values: Wallpapers.wallpapers
    }

    remove: Transition {
      NumberAnimation {
        property: "opacity"
        to: 0
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
      NumberAnimation {
        property: "scale"
        to: 0.6
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
    }

    add: Transition {
      NumberAnimation {
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
      NumberAnimation {
        property: "scale"
        from: 0.6
        to: 1
        duration: Theme.animMove
        easing.type: Easing.OutBack
      }
    }

    displaced: Transition {
      NumberAnimation {
        properties: "x,y"
        duration: Theme.animSlide
        easing.type: Easing.OutCubic
      }
      NumberAnimation {
        properties: "opacity,scale"
        to: 1
        duration: Theme.animMove
      }
    }

    delegate: ImageTile {
      id: tile

      required property string modelData
      readonly property bool active: root.selected === modelData
      readonly property bool upscaling: WallpaperTools.active === modelData
      readonly property bool canUpscale: Wallpapers.canUpscale(modelData)

      width: grid.cellWidth
      height: grid.cellHeight
      source: Paths.fileUrl(modelData)
      resolution: Wallpapers.resolutionOf(modelData)
      resolutionColor: canUpscale ? Theme.warn : Theme.text
      readonly property bool working: WallpaperTools.isBusy(modelData)

      showResolution: hovered && !active && !working
      checked: Wallpapers.current === modelData
      badged: Wallpapers.isSafe(modelData)
      dimmed: working
      onClicked: root.selected = active ? "" : modelData
      onRightClicked: Wallpapers.toggleSafe(modelData)

      Text {
        anchors.centerIn: parent
        visible: tile.upscaling && !tile.active
        text: Math.floor(WallpaperTools.progress * 100) + "%"
        color: Theme.text
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuTitleSize + 2
        font.bold: true
      }

      Column {
        anchors.centerIn: parent
        visible: tile.working && !tile.upscaling && !tile.active
        spacing: 2

        Icon {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "schedule"
          color: Theme.text
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Queued"
          color: Theme.text
          font.family: Theme.labelFont
          font.pixelSize: 12
        }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        height: 4
        radius: 2
        color: Qt.alpha(Theme.surface, 0.7)
        visible: tile.upscaling

        Rectangle {
          width: parent.width * WallpaperTools.progress
          height: parent.height
          radius: parent.radius
          color: Theme.primary

          Behavior on width {
            NumberAnimation {
              duration: Theme.animMove
              easing.type: Theme.easeOut
            }
          }
        }
      }

      Rectangle {
        anchors.fill: parent
        radius: tile.frame.radius
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
            text: tile.upscaling ? "Upscaling…" : tile.working ? "Queued" : tile.canUpscale ? "Upscale" : "Already sharp"
            available: tile.canUpscale && !tile.working
            onClicked: {
              root.selected = "";
              WallpaperTools.upscale(tile.modelData);
            }
          }

          Chip {
            width: tile.frame.width - 24
            icon: "verified_user"
            text: tile.badged ? "Unmark safe" : "Mark safe"
            onClicked: {
              root.selected = "";
              Wallpapers.toggleSafe(tile.modelData);
            }
          }

          Chip {
            width: tile.frame.width - 24
            icon: "delete"
            text: "Delete"
            available: !tile.working
            onClicked: {
              root.selected = "";
              WallpaperTools.trash(tile.modelData);
            }
          }
        }
      }
    }
  }
}
