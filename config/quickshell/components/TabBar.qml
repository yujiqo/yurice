import QtQuick
import qs.theme

Item {
  id: root

  property var model: []
  property string current: ""

  signal selected(string id)

  implicitWidth: row.implicitWidth + 8
  implicitHeight: 40

  readonly property Item currentItem: {
    for (let i = 0; i < repeater.count; i++) {
      const item = repeater.itemAt(i);
      if (item && item.modelData.id === root.current)
        return item;
    }
    return null;
  }

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: Theme.surfaceContainer
  }

  Rectangle {
    id: indicator
    y: 4
    height: parent.height - 8
    radius: height / 2
    color: Theme.primary
    visible: root.currentItem !== null
    x: root.currentItem ? row.x + root.currentItem.x : 4
    width: root.currentItem ? root.currentItem.width : 0

    Behavior on x {
      NumberAnimation {
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
    }
    Behavior on width {
      NumberAnimation {
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
    }
  }

  Row {
    id: row
    x: 4
    anchors.verticalCenter: parent.verticalCenter

    Repeater {
      id: repeater
      model: root.model

      Chip {
        required property var modelData
        flat: true
        height: root.height - 8
        icon: modelData.icon ?? ""
        text: modelData.name
        available: modelData.enabled ?? true
        selected: root.current === modelData.id
        onClicked: root.selected(modelData.id)
      }
    }
  }
}
