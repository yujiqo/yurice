pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

ListView {
  id: root

  property bool followCurrent: false

  function step(delta) {
    currentIndex = Math.max(0, Math.min(count - 1, currentIndex + delta));
  }

  width: parent.width
  height: Math.min(contentHeight, Theme.menuListMaxHeight)
  clip: true
  spacing: Theme.menuGap
  boundsBehavior: Flickable.StopAtBounds
  interactive: contentHeight > height
  onCurrentIndexChanged: {
    if (followCurrent)
      positionViewAtIndex(currentIndex, ListView.Contain);
  }
}
