import QtQuick
import QtQuick.Layouts
import qs.theme

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property color iconColor: Theme.bad
  property var segments: [
    {
      icon: root.icon,
      label: root.label,
      color: root.iconColor
    }
  ]
  property int maxLabelWidth: 400

  property bool clickable: false
  signal clicked(var mouse)

  implicitWidth: row.implicitWidth + Theme.pillPadding * 2
  implicitHeight: Theme.pillHeight
  radius: height / 2
  color: mouse.containsMouse ? Theme.surfaceHover : Theme.surface
  scale: mouse.pressed ? 0.95 : 1

  Behavior on implicitWidth {
    NumberAnimation {
      duration: Theme.animResize
      easing.type: Theme.easeOut
    }
  }
  Behavior on color {
    ColorAnimation {
      duration: Theme.animHover
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: Theme.animPress
    }
  }

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: Theme.pillSegmentGap

    Repeater {
      model: root.segments

      RowLayout {
        id: segment
        required property var modelData
        required property int index
        spacing: Theme.pillIconGap

        Rectangle {
          visible: segment.index > 0
          Layout.preferredWidth: 1
          Layout.preferredHeight: 14
          Layout.rightMargin: 3
          color: Theme.divider
        }

        Text {
          text: segment.modelData.icon ?? ""
          visible: text !== ""
          color: segment.modelData.color ?? root.iconColor
          font.family: Theme.iconFont
          font.pixelSize: Theme.iconSize
          Behavior on color {
            ColorAnimation {
              duration: Theme.animColor
            }
          }
        }

        Text {
          text: segment.modelData.label ?? ""
          visible: text !== ""
          color: Theme.text
          font.family: Theme.labelFont
          font.pixelSize: Theme.labelSize
          elide: Text.ElideRight
          Layout.maximumWidth: root.maxLabelWidth
        }
      }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: root.clickable
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: event => root.clicked(event)
  }
}
