pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Item {
  id: root

  property string current: ""
  property var order: []
  property string shown: ""
  property real fade: 1
  property real slide: 0
  property int direction: 1

  visible: false

  Component.onCompleted: shown = current

  onCurrentChanged: {
    if (shown === "")
      return;
    direction = order.indexOf(current) >= order.indexOf(shown) ? 1 : -1;
    anim.restart();
  }

  SequentialAnimation {
    id: anim

    ParallelAnimation {
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
    }
    ScriptAction {
      script: {
        root.shown = root.current;
        root.slide = root.direction * Theme.slideDistance;
      }
    }
    ParallelAnimation {
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
        easing.type: Theme.easeOut
      }
    }
  }
}
