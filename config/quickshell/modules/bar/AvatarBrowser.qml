pragma ComponentBehavior: Bound
import QtQuick
import Qt.labs.folderlistmodel
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  readonly property int columns: 5

  spacing: 8

  Row {
    width: parent.width
    spacing: 4

    IconButton {
      anchors.verticalCenter: parent.verticalCenter
      icon: "arrow_upward"
      opacity: AvatarEditor.folder !== "/" ? 1 : 0.4
      onClicked: AvatarEditor.parentFolder()
    }

    IconButton {
      anchors.verticalCenter: parent.verticalCenter
      icon: "home"
      onClicked: AvatarEditor.navigate(Paths.home)
    }

    TextField {
      width: parent.width - 72
      implicitHeight: 40
      leadingIcon: "folder"
      escapeLeaves: true
      text: Paths.display(AvatarEditor.folder)
      onAccepted: text => {
        const value = text.trim();
        if (value.startsWith("/") || value.startsWith("~"))
          AvatarEditor.navigate(Paths.expand(value));
        blur();
      }
      onInputActiveFocusChanged: {
        if (!inputActiveFocus)
          text = Qt.binding(() => Paths.display(AvatarEditor.folder));
      }
    }
  }

  property string shownFolder: AvatarEditor.folder
  property int direction: 1
  property real slide: 0
  property real fade: 1
  property bool waitingForFolder: false

  Connections {
    target: AvatarEditor
    function onFolderChanged() {
      const next = AvatarEditor.folder;
      const current = root.shownFolder;
      root.direction = current.startsWith(next) && current !== next ? -1 : 1;
      leaveAnim.restart();
    }
  }

  function enter() {
    waitingForFolder = false;
    enterFallback.stop();
    enterAnim.restart();
  }

  function swapFolder() {
    const changed = shownFolder !== AvatarEditor.folder;
    shownFolder = AvatarEditor.folder;
    grid.positionViewAtBeginning();
    slide = direction * Theme.slideDistance;
    if (changed && files.status !== FolderListModel.Ready) {
      waitingForFolder = true;
      enterFallback.restart();
    } else {
      Qt.callLater(enter);
    }
  }

  ParallelAnimation {
    id: leaveAnim

    onStarted: enterAnim.stop()

    NumberAnimation {
      target: root
      property: "fade"
      to: 0
      duration: Theme.animPress
      easing.type: Easing.InQuad
    }
    NumberAnimation {
      target: root
      property: "slide"
      to: -root.direction * Theme.slideDistance / 2
      duration: Theme.animPress
      easing.type: Easing.InQuad
    }

    onFinished: root.swapFolder()
  }

  ParallelAnimation {
    id: enterAnim

    NumberAnimation {
      target: root
      property: "fade"
      to: 1
      duration: Theme.animMove
      easing.type: Easing.OutQuad
    }
    NumberAnimation {
      target: root
      property: "slide"
      to: 0
      duration: Theme.animSlide
      easing.type: Easing.OutCubic
    }
  }

  Timer {
    id: enterFallback
    interval: 600
    onTriggered: root.enter()
  }

  Item {
    width: parent.width
    height: 380
    clip: true

    GridView {
      id: grid
      anchors.fill: parent
      cellWidth: Math.floor(width / root.columns)
      cellHeight: cellWidth
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      opacity: root.fade
      transform: Translate {
        x: root.slide
      }
      model: FolderListModel {
        id: files
        folder: Paths.fileUrl(root.shownFolder)
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.bmp"]
        caseSensitive: false
        showDirsFirst: true
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        onStatusChanged: {
          if (status === FolderListModel.Ready && root.waitingForFolder)
            root.enter();
        }
      }

      delegate: Item {
        id: cell

        required property string fileName
        required property string filePath
        required property bool fileIsDir

        width: grid.cellWidth
        height: grid.cellHeight

        ImageTile {
          anchors.fill: parent
          visible: !cell.fileIsDir
          source: cell.fileIsDir ? "" : Paths.fileUrl(cell.filePath)
          onClicked: AvatarEditor.pick(cell.filePath)
        }

        Rectangle {
          anchors.fill: parent
          anchors.margins: 3
          visible: cell.fileIsDir
          radius: Theme.menuItemRadius - 2
          color: folderMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
          scale: folderMouse.pressed ? 0.96 : 1

          Behavior on color {
            ColorAnimation {
              duration: Theme.animHover
            }
          }

          Behavior on scale {
            NumberAnimation {
              duration: Theme.animMove
              easing.type: Theme.easeOut
            }
          }

          Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -8
            text: "folder"
            color: Theme.primary
            size: 30
          }

          Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 6
            horizontalAlignment: Text.AlignHCenter
            text: cell.fileName
            elide: Text.ElideMiddle
            color: Theme.text
            font.family: Theme.labelFont
            font.pixelSize: Theme.menuSubtitleSize - 2
          }

          MouseArea {
            id: folderMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: AvatarEditor.navigate(cell.filePath)
          }
        }
      }
    }

    Text {
      anchors.centerIn: parent
      visible: files.status === FolderListModel.Ready && files.count === 0
      opacity: root.fade
      text: "No images or folders here"
      color: Theme.textVariant
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuSubtitleSize
    }
  }
}
