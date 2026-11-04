import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property string iconColor: "#ff6b6b"
  property int maxLabelWidth: 400

  implicitWidth: row.implicitWidth + 20
  implicitHeight: 30
  radius: height / 2
  color: "#040e0d"

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 5

    Text {
      text: root.icon
      color: root.iconColor
      font.family: "Material Symbols Sharp"
      font.pixelSize: 16
    }

    Text {
      text: root.label
      color: "#f5e2c5"
      font.family: "Agave Nerd Font"
      font.pixelSize: 16
      elide: Text.ElideRight
      Layout.maximumWidth: root.maxLabelWidth
      visible: root.label !== ""
    }
  }
}
