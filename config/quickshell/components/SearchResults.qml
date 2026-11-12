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
  property var thumbFor: item => item.thumb
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

  Flickable {
    id: grid

    readonly property int columns: 3
    readonly property real gap: 6
    readonly property real columnWidth: width / columns
    readonly property real footerHeight: root.feed.loadingMore ? 40 : 0
    readonly property var layout: {
      const heights = new Array(columns).fill(0);
      const cells = [];
      for (const item of root.feed.results) {
        const ratio = item.ratio > 0 ? Math.max(0.4, Math.min(2.5, item.ratio)) : 0;
        const h = ratio > 0 ? (columnWidth - gap) / ratio + gap : Theme.thumbHeight + gap;
        let c = 0;
        for (let i = 1; i < columns; i++) {
          if (heights[i] < heights[c] - 0.5)
            c = i;
        }
        cells.push({
          x: c * columnWidth,
          y: heights[c],
          height: h
        });
        heights[c] += h;
      }
      return {
        cells: cells,
        height: Math.max(...heights)
      };
    }

    width: parent.width
    height: Math.min(contentHeight, root.maxHeight)
    visible: root.showGrid
    clip: true
    contentWidth: width
    contentHeight: layout.height + footerHeight
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    function fill() {
      if (root.showGrid && root.feed.hasMore && layout.height < root.maxHeight)
        root.feed.loadMore();
    }

    onLayoutChanged: Qt.callLater(fill)
    onAtYEndChanged: {
      if (atYEnd && contentHeight > height)
        root.feed.loadMore();
    }

    Repeater {
      model: ScriptModel {
        values: root.feed.results
      }

      delegate: ImageTile {
        required property var modelData
        required property int index
        readonly property var cell: grid.layout.cells[index] ?? {
          x: 0,
          y: 0,
          height: 0
        }

        x: cell.x
        y: cell.y
        width: grid.columnWidth
        height: cell.height
        source: root.thumbFor(modelData)
        resolution: modelData.resolution
        busy: root.busyFor(modelData)
        checked: root.checkedFor(modelData)
        onClicked: root.activated(modelData)
      }
    }

    Item {
      y: grid.layout.height
      width: grid.width
      height: grid.footerHeight

      Spinner {
        anchors.centerIn: parent
        visible: root.feed.loadingMore
        tint: root.tint
      }
    }
  }

  Scrollbar {
    flickable: grid
  }
}
