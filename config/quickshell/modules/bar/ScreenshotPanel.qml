pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

Item {
  id: root

  readonly property bool keepOpen: true
  readonly property real gap: 12
  readonly property real columnWidth: (width - gap - 1) / 2
  readonly property var columns: [
    {
      region: true,
      hints: [
        {
          keys: ["Ctrl", "C"],
          label: "Copy region"
        },
        {
          keys: ["Ctrl", "S"],
          label: "Save region"
        }
      ]
    },
    {
      region: false,
      hints: [
        {
          keys: ["Ctrl", "Shift", "S"],
          label: "Full screen"
        },
        {
          keys: ["P"],
          label: Screenshot.showPointer ? "Hide pointer" : "Show pointer"
        }
      ]
    }
  ]

  implicitHeight: layout.implicitHeight + 6

  Row {
    id: layout
    width: parent.width
    spacing: root.gap / 2

    Repeater {
      model: root.columns

      Row {
        id: column

        required property var modelData
        required property int index

        spacing: root.gap / 2

        Rectangle {
          visible: column.index > 0
          width: 1
          height: hints.height - 8
          anchors.verticalCenter: parent.verticalCenter
          color: Theme.divider
        }

        Column {
          id: hints
          width: root.columnWidth
          opacity: column.modelData.region && !Screenshot.hasSelection ? 0.4 : 1

          Behavior on opacity {
            NumberAnimation {
              duration: Theme.animHover
            }
          }

          Repeater {
            model: column.modelData.hints

            KeyRow {
              required property var modelData

              width: hints.width
              label: modelData.label
              keys: modelData.keys
            }
          }
        }
      }
    }
  }
}
