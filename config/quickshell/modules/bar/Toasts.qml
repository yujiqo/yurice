import QtQuick
import qs.theme
import qs.components
import qs.services

ListView {
  id: list

  width: Theme.toastWidth
  height: Theme.dropdownMaxHeight
  spacing: Theme.barGap
  interactive: false
  model: Notifications.toasts

  add: Transition {
    NumberAnimation {
      property: "opacity"
      from: 0
      to: 1
      duration: Theme.animMove
      easing.type: Theme.easeOut
    }
    NumberAnimation {
      property: "scale"
      from: 0.9
      to: 1
      duration: Theme.animMove
      easing.type: Easing.OutBack
    }
  }

  remove: Transition {
    NumberAnimation {
      property: "opacity"
      to: 0
      duration: Theme.animMove
      easing.type: Theme.easeOut
    }
    NumberAnimation {
      property: "scale"
      to: 0.9
      duration: Theme.animMove
      easing.type: Theme.easeOut
    }
  }

  displaced: Transition {
    NumberAnimation {
      property: "y"
      duration: Theme.animSlide
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      properties: "opacity,scale"
      to: 1
      duration: Theme.animMove
    }
  }

  delegate: Item {
    id: toast

    required property int uid
    required property string appName
    required property string summary
    required property string body
    required property string appIcon
    required property string image
    required property string symbol
    required property bool critical
    required property int timeout
    required property int generation
    readonly property var source: Notifications.source(uid)
    property var actions: []
    readonly property string picture: image !== "" ? image : appIcon

    function captureActions() {
      if (source)
        actions = source.actions.filter(a => a.identifier !== "default").map(a => ({
              identifier: a.identifier,
              text: a.text
            }));
    }

    onSourceChanged: captureActions()
    Component.onCompleted: captureActions()

    width: list.width
    height: card.height
    transformOrigin: Item.Top

    onGenerationChanged: if (timer.running)
      timer.restart()

    Timer {
      id: timer
      interval: toast.timeout
      running: toast.timeout > 0 && !hover.hovered
      onTriggered: Notifications.close(toast.uid, false)
    }

    Rectangle {
      id: card
      width: parent.width
      height: Math.max(row.implicitHeight, 40) + 24
      radius: Theme.panelRadius
      color: hover.hovered ? Theme.surfaceHover : Theme.surface
      border.width: toast.critical ? 1 : 0
      border.color: Theme.error
      scale: mouse.pressed ? 0.97 : 1

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

      HoverHandler {
        id: hover
      }

      MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => event.button === Qt.RightButton ? Notifications.close(toast.uid, true) : Notifications.activate(toast.uid)
      }

      Row {
        id: row
        x: 12
        y: 12
        width: parent.width - 24
        spacing: 12

        Item {
          width: 40
          height: 40

          Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.secondaryContainer
            visible: toast.picture === ""

            Icon {
              anchors.centerIn: parent
              text: toast.symbol !== "" ? toast.symbol : "notifications"
              color: Theme.onSecondaryContainer
            }
          }

          RoundedImage {
            anchors.fill: parent
            visible: toast.picture !== ""
            radius: toast.image !== "" ? 10 : 0
            source: toast.picture
            sourceSize: Qt.size(80, 80)
          }
        }

        Column {
          width: parent.width - 52
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            width: parent.width
            visible: toast.appName !== ""
            text: toast.appName
            elide: Text.ElideRight
            color: Theme.textVariant
            font.family: Theme.labelFont
            font.pixelSize: Theme.menuSubtitleSize - 1
          }

          Text {
            width: parent.width
            text: toast.summary
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.labelFont
            font.pixelSize: Theme.menuTitleSize
            font.bold: true
          }

          Text {
            width: parent.width
            visible: toast.body !== ""
            text: toast.body
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: Theme.textVariant
            font.family: Theme.labelFont
            font.pixelSize: Theme.menuSubtitleSize
          }

          Flow {
            width: parent.width
            visible: toast.actions.length > 0
            topPadding: 6
            spacing: 6

            Repeater {
              model: toast.actions

              Chip {
                required property var modelData
                text: modelData.text
                onClicked: Notifications.invoke(toast.uid, modelData.identifier)
              }
            }
          }
        }
      }
    }
  }
}
