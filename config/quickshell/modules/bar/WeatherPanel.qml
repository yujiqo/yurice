import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  spacing: Theme.menuGap

  readonly property real weekMin: Math.min(...Weather.days.map(d => d.min))
  readonly property real weekMax: Math.max(...Weather.days.map(d => d.max))
  readonly property var today: Weather.days[0] ?? null

  function time(date) {
    return date ? Qt.formatTime(date, "HH:mm") : "–";
  }

  Item {
    width: parent.width
    height: 96

    Icon {
      id: bigIcon
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: Weather.current.icon
      color: Theme.weather
      size: 56
      fill: 1
    }

    Column {
      anchors.left: bigIcon.right
      anchors.leftMargin: 14
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      Text {
        text: Math.round(Weather.temperature) + "°C"
        color: Theme.text
        font.family: Theme.labelFont
        font.pixelSize: 40
      }

      Label {
        width: parent.width
        text: Weather.city ? `${Weather.current.text} · ${Weather.city}` : Weather.current.text
        color: Theme.textVariant
        pixelSize: Theme.menuSubtitleSize + 1
      }
    }

    Spinner {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.topMargin: 6
      visible: Weather.loading
    }
  }

  Rectangle {
    width: parent.width
    implicitHeight: details.implicitHeight + 8
    height: implicitHeight
    radius: Theme.menuItemRadius
    color: Theme.surfaceContainer

    Grid {
      id: details
      y: 4
      width: parent.width
      columns: 2

      InfoRow {
        width: details.width / 2
        icon: "device_thermostat"
        label: "Feels"
        value: Math.round(Weather.feelsLike) + "°"
      }
      InfoRow {
        width: details.width / 2
        icon: "humidity_percentage"
        label: "Humidity"
        value: Weather.humidity + "%"
      }
      InfoRow {
        width: details.width / 2
        icon: "air"
        label: "Wind"
        value: Math.round(Weather.wind) + " km/h"
      }
      InfoRow {
        width: details.width / 2
        icon: "water_drop"
        label: "Rain"
        value: (root.today?.rain ?? 0) + "%"
      }
      InfoRow {
        width: details.width / 2
        icon: "wb_twilight"
        label: "Rise"
        value: root.time(root.today?.sunrise)
      }
      InfoRow {
        width: details.width / 2
        icon: "bedtime"
        label: "Set"
        value: root.time(root.today?.sunset)
      }
    }
  }

  Text {
    leftPadding: 12
    topPadding: 6
    bottomPadding: 2
    text: "7-day forecast"
    color: Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuSubtitleSize
  }

  Column {
    width: parent.width

    Repeater {
      model: Weather.days

      Item {
        id: day

        required property var modelData
        required property int index
        readonly property var info: Weather.describe(modelData.code, true)
        readonly property real span: Math.max(1, root.weekMax - root.weekMin)

        width: root.width
        height: 32

        Text {
          id: dayName
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          width: 58
          text: day.index === 0 ? "Today" : Qt.formatDate(day.modelData.date, "ddd")
          color: day.index === 0 ? Theme.text : Theme.textVariant
          font.family: Theme.labelFont
          font.pixelSize: Theme.menuSubtitleSize + 1
        }

        Icon {
          id: dayIcon
          anchors.left: dayName.right
          anchors.verticalCenter: parent.verticalCenter
          width: 26
          horizontalAlignment: Text.AlignHCenter
          text: day.info.icon
          color: Theme.weather
          size: Theme.menuIconSize - 2
        }

        Text {
          id: rain
          anchors.left: dayIcon.right
          anchors.leftMargin: 4
          anchors.verticalCenter: parent.verticalCenter
          width: 38
          text: day.modelData.rain >= 10 ? day.modelData.rain + "%" : ""
          color: Theme.tertiary
          font.family: Theme.labelFont
          font.pixelSize: Theme.menuSubtitleSize - 1
        }

        Text {
          id: low
          anchors.left: rain.right
          anchors.verticalCenter: parent.verticalCenter
          width: 34
          horizontalAlignment: Text.AlignRight
          text: Math.round(day.modelData.min) + "°"
          color: Theme.textVariant
          font.family: Theme.labelFont
          font.pixelSize: Theme.menuSubtitleSize + 1
        }

        Item {
          id: track
          anchors.left: low.right
          anchors.leftMargin: 10
          anchors.right: high.left
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          height: 6

          Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.surfaceContainerHighest
          }

          Rectangle {
            x: track.width * (day.modelData.min - root.weekMin) / day.span
            width: Math.max(height, track.width * (day.modelData.max - day.modelData.min) / day.span)
            height: parent.height
            radius: height / 2
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop {
                position: 0
                color: Theme.tertiary
              }
              GradientStop {
                position: 1
                color: Theme.primary
              }
            }
          }
        }

        Text {
          id: high
          anchors.right: parent.right
          anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          width: 34
          horizontalAlignment: Text.AlignRight
          text: Math.round(day.modelData.max) + "°"
          color: Theme.text
          font.family: Theme.labelFont
          font.pixelSize: Theme.menuSubtitleSize + 1
        }
      }
    }
  }
}
