import QtQuick
import qs.theme

Item {
  id: root

  property bool shown: true
  property bool animate: true
  default property alias content: holder.data
  readonly property real progress: Math.max(0, Math.min(1, spring.value))

  implicitWidth: (holder.width + Theme.barGap) * spring.value - Theme.barGap
  implicitHeight: holder.height
  visible: spring.value > 0.001

  onShownChanged: {
    if (animate)
      spring.target = shown ? 1 : 0;
    else
      spring.jump(shown ? 1 : 0);
  }

  Spring {
    id: spring
    Component.onCompleted: jump(root.shown ? 1 : 0)
  }

  Item {
    id: holder
    width: childrenRect.width
    height: childrenRect.height
    opacity: root.progress
    scale: 0.8 + 0.2 * root.progress
  }
}
