import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  readonly property var player: Media.active
  readonly property bool playing: player !== null
  readonly property int barsWidth: 14

  padding: (Theme.pillHeight - barsWidth) / 2
  spacing: 0
  width: implicitWidth * Math.max(0, appear.value)
  opacity: Math.max(0, Math.min(1, appear.value))
  visible: appear.value > 0.01

  Spring {
    id: appear
    target: root.playing ? 1 : 0
    Component.onCompleted: value = target
  }

  Item {
    width: root.barsWidth
    height: Theme.pillHeight

    Row {
      anchors.centerIn: parent
      height: root.barsWidth
      spacing: 2.5

      Repeater {
        model: 3

        Rectangle {
          id: bar
          required property int index
          readonly property int period: 280 + index * 110

          anchors.verticalCenter: parent.verticalCenter
          width: 3
          height: 4
          radius: 1.5
          color: Theme.music

          SequentialAnimation on height {
            running: root.playing
            loops: Animation.Infinite
            NumberAnimation {
              to: root.barsWidth
              duration: bar.period
              easing.type: Easing.InOutSine
            }
            NumberAnimation {
              to: 4
              duration: bar.period
              easing.type: Easing.InOutSine
            }
          }
        }
      }
    }
  }

  Reveal {
    shown: root.hovered && root.playing
    leading: Theme.pillSegmentGap

    Text {
      readonly property string artist: root.player?.trackArtist || "Unknown"
      readonly property string title: root.player?.trackTitle || ""
      text: title ? `${artist} — ${title}` : artist
      width: Math.min(implicitWidth, 300)
      elide: Text.ElideRight
      color: Theme.text
      font.family: Theme.labelFont
      font.pixelSize: Theme.labelSize
    }
  }
}
