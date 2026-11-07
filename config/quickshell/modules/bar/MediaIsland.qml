import QtQuick
import qs.theme
import qs.components
import qs.services

Island {
  id: root

  readonly property var player: Media.active
  readonly property bool present: player !== null
  readonly property bool playing: player?.isPlaying ?? false
  readonly property int barsWidth: 14

  open: current === "media"
  panel: current === "media" ? mediaPanel : null
  panelWidth: Theme.mediaPanelWidth
  clickable: true
  onClicked: request("media")
  padding: (Theme.pillHeight - barsWidth) / 2
  spacing: 0
  width: implicitWidth * Math.max(0, appear.value)
  opacity: Math.max(0, Math.min(1, appear.value))
  visible: appear.value > 0.01

  onPresentChanged: {
    if (!present && open)
      dismissed();
  }

  Spring {
    id: appear
    target: root.present ? 1 : 0
    Component.onCompleted: value = target
  }

  Component {
    id: mediaPanel

    MediaPanel {}
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
          color: root.playing ? Theme.music : Theme.off

          Behavior on color {
            ColorAnimation {
              duration: Theme.animColor
            }
          }

          SequentialAnimation on height {
            running: root.playing
            loops: Animation.Infinite
            onRunningChanged: {
              if (!running)
                bar.height = 4;
            }
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
    shown: root.expanded && root.present
    leading: Theme.pillSegmentGap

    Label {
      readonly property string artist: root.player?.trackArtist || "Unknown"
      readonly property string title: root.player?.trackTitle || ""
      text: title ? `${artist} — ${title}` : artist
      maxWidth: 300
    }
  }
}
