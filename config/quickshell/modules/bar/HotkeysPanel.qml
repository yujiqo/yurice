pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

Item {
  id: root

  readonly property bool keepOpen: true
  readonly property real step: 32

  implicitHeight: Math.min(content.implicitHeight, Theme.dropdownMaxHeight - Theme.pillHeight - Theme.panelPadding * 2)
  focus: true

  Component.onCompleted: forceActiveFocus()

  function scrollTo(y) {
    scroll.to = Math.max(0, Math.min(flick.contentHeight - flick.height, y));
    scroll.restart();
  }

  function scrollBy(dy) {
    scrollTo((scroll.running ? scroll.to : flick.contentY) + dy);
  }

  NumberAnimation {
    id: scroll
    target: flick
    property: "contentY"
    duration: Theme.animResize
    easing.type: Theme.easeOut
  }

  Keys.onPressed: event => {
    const ctrl = event.modifiers & Qt.ControlModifier;
    if (event.modifiers & (Qt.AltModifier | Qt.MetaModifier))
      return;
    if (!ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_Down))
      scrollBy(step);
    else if (!ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_Up))
      scrollBy(-step);
    else if ((ctrl && event.key === Qt.Key_D) || event.key === Qt.Key_PageDown)
      scrollBy(flick.height / 2);
    else if ((ctrl && event.key === Qt.Key_U) || event.key === Qt.Key_PageUp)
      scrollBy(-flick.height / 2);
    else if (event.key === Qt.Key_G && (event.modifiers & Qt.ShiftModifier))
      scrollTo(flick.contentHeight);
    else if (!ctrl && (event.key === Qt.Key_G || event.key === Qt.Key_Home))
      scrollTo(0);
    else if (event.key === Qt.Key_End)
      scrollTo(flick.contentHeight);
    else
      return;
    event.accepted = true;
  }

  Flickable {
    id: flick
    anchors.fill: parent
    anchors.bottomMargin: 4
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: content
      width: flick.width
      spacing: 14

      Repeater {
        model: Hotkeys.sections

        Column {
          id: section

          required property var modelData

          width: content.width
          spacing: 2

          Text {
            leftPadding: 8
            bottomPadding: 4
            text: section.modelData.title.toUpperCase()
            color: Theme.clock
            font.family: Theme.labelFont
            font.pixelSize: Theme.menuSubtitleSize - 2
            font.letterSpacing: 1
            font.bold: true
          }

          Repeater {
            model: section.modelData.binds

            Rectangle {
              id: entry

              required property var modelData

              width: section.width
              height: root.step
              radius: Theme.menuItemRadius / 2
              color: hover.hovered ? Theme.surfaceContainer : "transparent"

              HoverHandler {
                id: hover
              }

              Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: keys.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: entry.modelData.title
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.labelFont
                font.pixelSize: Theme.menuSubtitleSize
              }

              Row {
                id: keys
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                  model: entry.modelData.keys

                  Keycap {
                    required property string modelData
                    text: modelData
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
