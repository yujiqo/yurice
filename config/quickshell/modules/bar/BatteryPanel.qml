import QtQuick
import Quickshell.Services.UPower
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  readonly property var profiles: {
    const list = [
      {
        profile: PowerProfile.PowerSaver,
        icon: "eco",
        label: "Saver"
      },
      {
        profile: PowerProfile.Balanced,
        icon: "balance",
        label: "Balanced"
      }
    ];
    if (PowerProfiles.hasPerformanceProfile)
      list.push({
        profile: PowerProfile.Performance,
        icon: "speed",
        label: "Performance"
      });
    return list;
  }

  spacing: 8

  Item {
    width: parent.width
    height: 64

    Icon {
      id: heroIcon
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: Battery.icon
      color: Battery.color
      size: 44
    }

    Column {
      anchors.left: heroIcon.right
      anchors.leftMargin: 14
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Label {
        text: Battery.percent + "%"
        color: Theme.text
        pixelSize: 30
      }

      Label {
        width: parent.width
        text: Battery.status
        color: Theme.textVariant
        pixelSize: Theme.menuSubtitleSize
      }
    }
  }

  Item {
    width: parent.width
    height: 14

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      height: 8
      radius: height / 2
      color: Theme.surfaceContainerHighest

      Rectangle {
        width: parent.width * Math.min(1, Battery.percent / 100)
        height: parent.height
        radius: height / 2
        color: Battery.color
        Behavior on width {
          NumberAnimation {
            duration: Theme.animSlide
            easing.type: Theme.easeOut
          }
        }
      }

      Rectangle {
        visible: Battery.limit > 0 && Battery.limit < 100
        x: parent.width * Battery.limit / 100 - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 14
        radius: 1.5
        color: Theme.text
      }
    }
  }

  Rectangle {
    width: parent.width
    height: details.implicitHeight + 8
    radius: Theme.menuItemRadius
    color: Theme.surfaceContainer

    Column {
      id: details
      y: 4
      width: parent.width

      InfoRow {
        width: parent.width
        icon: "bolt"
        label: Battery.charging ? "Charging at" : "Power draw"
        value: Battery.rate > 0 ? Battery.rate.toFixed(1) + " W" : "—"
      }

      InfoRow {
        width: parent.width
        icon: "battery_android_full"
        label: "Energy"
        value: `${Battery.energy.toFixed(1)} / ${Battery.energyFull.toFixed(1)} Wh`
      }

      InfoRow {
        width: parent.width
        visible: Battery.health > 0
        icon: "favorite"
        label: "Health"
        value: Battery.designWh > 0 ? `${Math.round(Battery.health)}% of ${Battery.designWh.toFixed(1)} Wh` : Math.round(Battery.health) + "%"
      }

      InfoRow {
        width: parent.width
        visible: Battery.cycles >= 0
        icon: "autorenew"
        label: "Cycles"
        value: Battery.cycles
      }

      InfoRow {
        width: parent.width
        visible: Battery.limit > 0 && Battery.limit < 100
        icon: "vertical_align_top"
        label: "Charge limit"
        value: Battery.limit + "%"
      }

      InfoRow {
        width: parent.width
        visible: value !== ""
        icon: "info"
        label: "Battery"
        value: [Battery.vendor, Battery.technology].filter(s => s !== "").join(" · ")
      }
    }
  }

  Item {
    id: profileGroup

    readonly property real gap: 4
    readonly property real compactWidth: 52
    readonly property real selectedWidth: width - (root.profiles.length - 1) * (compactWidth + gap)

    width: parent.width
    height: 44

    Row {
      spacing: profileGroup.gap

      Repeater {
        model: root.profiles

        Rectangle {
          id: button

          required property var modelData
          required property int index
          readonly property bool selected: PowerProfiles.profile === modelData.profile
          readonly property bool first: index === 0
          readonly property bool last: index === root.profiles.length - 1
          readonly property real outer: height / 2
          property real inner: selected ? height / 2 : 8

          width: selected ? profileGroup.selectedWidth : profileGroup.compactWidth
          height: profileGroup.height
          topLeftRadius: first ? outer : inner
          bottomLeftRadius: first ? outer : inner
          topRightRadius: last ? outer : inner
          bottomRightRadius: last ? outer : inner
          color: selected ? Theme.primary : buttonMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
          scale: buttonMouse.pressed ? 0.95 : 1

          Behavior on width {
            NumberAnimation {
              duration: Theme.animSlide
              easing.type: Easing.OutCubic
            }
          }
          Behavior on inner {
            NumberAnimation {
              duration: Theme.animSlide
              easing.type: Easing.OutCubic
            }
          }
          Behavior on color {
            ColorAnimation {
              duration: Theme.animColor
            }
          }
          Behavior on scale {
            NumberAnimation {
              duration: Theme.animPress
            }
          }

          Row {
            anchors.centerIn: parent
            height: parent.height

            Icon {
              anchors.verticalCenter: parent.verticalCenter
              text: button.modelData.icon
              color: button.selected ? Theme.onPrimary : Theme.textVariant
              size: Theme.menuIconSize
            }

            Reveal {
              anchors.verticalCenter: parent.verticalCenter
              shown: button.selected
              leading: 8

              Label {
                text: button.modelData.label
                color: Theme.onPrimary
                pixelSize: Theme.menuSubtitleSize + 1
              }
            }
          }

          MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: PowerProfiles.profile = button.modelData.profile
          }
        }
      }
    }
  }
}
