import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  property int year: Clock.date.getFullYear()
  property int month: Clock.date.getMonth()

  readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7
  readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
  readonly property int cellCount: Math.ceil((offset + daysInMonth) / 7) * 7
  readonly property real cellWidth: width / 7
  readonly property bool showingToday: year === Clock.date.getFullYear() && month === Clock.date.getMonth()

  property real wheelDelta: 0
  property real slideX: 0
  property real slideY: 0
  property real fade: 1

  function goTo(y, m) {
    const delta = (y - year) * 12 + (m - month);
    if (delta === 0)
      return;
    year = y;
    month = m;
    changeAnim.stop();
    if (Math.abs(delta) >= 12) {
      slideX = 0;
      slideY = Math.sign(delta) * Theme.slideDistance * 0.7;
    } else {
      slideX = Math.sign(delta) * Theme.slideDistance;
      slideY = 0;
    }
    fade = 0;
    changeAnim.start();
  }

  function shift(months) {
    const d = new Date(year, month + months, 1);
    goTo(d.getFullYear(), d.getMonth());
  }

  function today() {
    goTo(Clock.date.getFullYear(), Clock.date.getMonth());
  }

  ParallelAnimation {
    id: changeAnim

    NumberAnimation {
      target: root
      property: "slideX"
      to: 0
      duration: Theme.animSlide
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root
      property: "slideY"
      to: 0
      duration: Theme.animSlide
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root
      property: "fade"
      to: 1
      duration: Theme.animMove
      easing.type: Easing.OutQuad
    }
  }

  spacing: Theme.menuGap

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => {
      root.wheelDelta += event.angleDelta.y;
      while (root.wheelDelta >= 120) {
        root.wheelDelta -= 120;
        root.shift(1);
      }
      while (root.wheelDelta <= -120) {
        root.wheelDelta += 120;
        root.shift(-1);
      }
    }
  }

  Item {
    width: parent.width
    height: 44

    Row {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      IconButton {
        icon: "keyboard_double_arrow_left"
        onClicked: root.shift(-12)
      }

      IconButton {
        icon: "chevron_left"
        onClicked: root.shift(-1)
      }
    }

    Rectangle {
      readonly property bool active: titleMouse.containsMouse && !root.showingToday

      anchors.centerIn: parent
      width: Math.max(monthMetrics.width, hintMetrics.width) + 24
      height: 34
      radius: height / 2
      color: active ? Theme.surfaceContainerHigh : "transparent"

      Behavior on width {
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

      TextMetrics {
        id: monthMetrics
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuHeaderSize
        text: Qt.locale().standaloneMonthName(root.month) + " " + root.year
      }

      TextMetrics {
        id: hintMetrics
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuHeaderSize
        text: "Back to today"
      }

      Item {
        id: morph

        property real progress: parent.active ? 1 : 0

        anchors.fill: parent
        clip: true

        Behavior on progress {
          NumberAnimation {
            duration: Theme.animMove
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          y: (parent.height - height) / 2 - morph.progress * parent.height * 0.6
          opacity: (1 - Math.min(1, morph.progress * 1.5)) * root.fade
          transform: Translate {
            x: root.slideX * 0.5
            y: root.slideY * 0.5
          }
          scale: 1 - morph.progress * 0.15
          text: monthMetrics.text
          color: root.showingToday ? Theme.text : Theme.primary
          font: monthMetrics.font
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          y: (parent.height - height) / 2 + (1 - morph.progress) * parent.height * 0.6
          opacity: Math.max(0, morph.progress * 1.5 - 0.5)
          scale: 0.85 + morph.progress * 0.15
          text: hintMetrics.text
          color: Theme.primary
          font: hintMetrics.font
        }
      }

      MouseArea {
        id: titleMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.showingToday ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: root.today()
      }
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      IconButton {
        icon: "chevron_right"
        onClicked: root.shift(1)
      }

      IconButton {
        icon: "keyboard_double_arrow_right"
        onClicked: root.shift(12)
      }
    }
  }

  Row {
    Repeater {
      model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

      Text {
        required property string modelData
        width: root.cellWidth
        height: 24
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: modelData
        color: Theme.textVariant
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuSubtitleSize
      }
    }
  }

  Grid {
    columns: 7
    opacity: root.fade
    transform: Translate {
      x: root.slideX
      y: root.slideY
    }

    Repeater {
      model: root.cellCount

      Item {
        id: cell

        required property int index
        readonly property date day: new Date(root.year, root.month, 1 - root.offset + index)
        readonly property bool inMonth: day.getMonth() === root.month
        readonly property bool isToday: day.getFullYear() === Clock.date.getFullYear() && day.getMonth() === Clock.date.getMonth() && day.getDate() === Clock.date.getDate()
        readonly property bool weekend: index % 7 >= 5

        width: root.cellWidth
        height: 38

        Rectangle {
          anchors.centerIn: parent
          width: 34
          height: 34
          radius: width / 2
          color: Theme.primary
          visible: cell.isToday
        }

        Text {
          anchors.centerIn: parent
          text: cell.day.getDate()
          color: cell.isToday ? Theme.onPrimary : !cell.inMonth ? Theme.outline : cell.weekend ? Theme.textVariant : Theme.text
          opacity: cell.inMonth || cell.isToday ? 1 : 0.6
          font.family: Theme.labelFont
          font.pixelSize: Theme.menuTitleSize
        }
      }
    }
  }
}
