import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property string iconColor: "#ff6b6b"
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

  implicitWidth: row.implicitWidth + 20
  implicitHeight: 30
  radius: height / 2
  color: mouse.containsMouse ? "#0d1f1d" : "#040e0d"
  scale: mouse.pressed ? 0.95 : 1

  Behavior on implicitWidth {
    NumberAnimation {
      duration: 150
      easing.type: Easing.OutCubic
    }
  }
  Behavior on color {
    ColorAnimation {
      duration: 120
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: 100
    }
  }

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 8

    Repeater {
      model: root.segments

      RowLayout {
        id: segment
        required property var modelData
        required property int index
        spacing: 5

        Rectangle {
          visible: segment.index > 0
          Layout.preferredWidth: 1
          Layout.preferredHeight: 14
          Layout.rightMargin: 3
          color: "#3a4a48"
        }

        Text {
          text: segment.modelData.icon ?? ""
          visible: text !== ""
          color: segment.modelData.color ?? root.iconColor
          font.family: "Material Symbols Sharp"
          font.pixelSize: 16
          Behavior on color {
            ColorAnimation {
              duration: 200
            }
          }
        }

        Text {
          text: segment.modelData.label ?? ""
          visible: text !== ""
          color: "#f5e2c5"
          font.family: "Agave Nerd Font"
          font.pixelSize: 16
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
