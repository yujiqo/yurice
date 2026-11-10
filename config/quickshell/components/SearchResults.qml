pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.theme

Column {
  id: root

  required property var feed
  required property string label
  required property var busyFor
  required property var checkedFor
  property string emptyText: "Nothing found"
  property color tint: Theme.tertiary
  property bool blocked: false
  property real maxHeight: Theme.dropdownMaxHeight

  readonly property bool showSearching: feed.searching
  readonly property bool showMessage: !blocked && (feed.phase === "error" || (feed.phase === "results" && feed.results.length === 0))
  readonly property bool showGrid: !blocked && feed.phase === "results" && feed.results.length > 0

  signal activated(var item)

  width: parent.width
  spacing: Theme.menuGap
  visible: showSearching || showMessage || showGrid

  Item {
    width: parent.width
    height: 56
    visible: root.showSearching

    Row {
      anchors.centerIn: parent
      spacing: 6

      Spinner {
        anchors.verticalCenter: parent.verticalCenter
        tint: root.tint
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: `Searching ${root.label}…`
        color: Theme.text
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuTitleSize
      }
    }
  }

  EmptyState {
    height: 56
    visible: root.showMessage
    text: root.feed.phase === "error" ? root.feed.error : root.emptyText
  }

  GridView {
    id: grid

    readonly property int columns: 3

    width: parent.width
    height: Math.min(contentHeight, root.maxHeight)
    visible: root.showGrid
    clip: true
    cellWidth: width / columns
    cellHeight: Theme.thumbHeight + 6
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    model: ScriptModel {
      values: root.feed.results
    }
    onAtYEndChanged: {
      if (atYEnd && contentHeight > height)
        root.feed.loadMore();
    }

    footer: Item {
      width: grid.width
      height: root.feed.loadingMore ? 40 : 0

      Spinner {
        anchors.centerIn: parent
        visible: root.feed.loadingMore
        tint: root.tint
      }
    }

    delegate: ImageTile {
      required property var modelData

      width: grid.cellWidth
      height: grid.cellHeight
      source: modelData.thumb
      resolution: modelData.resolution
      busy: root.busyFor(modelData)
      checked: root.checkedFor(modelData)
      onClicked: root.activated(modelData)
    }
  }
}
