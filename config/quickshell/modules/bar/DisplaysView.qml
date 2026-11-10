pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  readonly property var output: Displays.outputs.find(o => o.name === Displays.selected) ?? null
  readonly property var current: output ? Displays.draft[output.name] ?? null : null
  readonly property var resolutions: {
    if (!output)
      return [];
    const seen = {};
    return output.modes.filter(m => {
      const key = m.width + "x" + m.height;
      if (seen[key])
        return false;
      seen[key] = true;
      return true;
    }).sort((a, b) => b.width * b.height - a.width * a.height || b.width - a.width);
  }
  readonly property var rates: output && state ? output.modes.filter(m => m.width === state.width && m.height === state.height).map(m => m.refresh).sort((a, b) => b - a) : []
  readonly property var rotations: [
    {
      value: "normal",
      label: "0°"
    },
    {
      value: "90",
      label: "90°"
    },
    {
      value: "180",
      label: "180°"
    },
    {
      value: "270",
      label: "270°"
    }
  ]
  readonly property bool locked: Displays.confirming || Displays.busy

  spacing: 10

  function hz(refresh) {
    const value = refresh / 1000;
    return (Math.abs(value - Math.round(value)) < 0.05 ? Math.round(value) : value.toFixed(2)) + " Hz";
  }

  component Section: Column {
    id: section

    property string title: ""
    property string icon: ""
    property string value: ""
    default property alias body: holder.data

    width: parent.width
    spacing: 4

    InfoRow {
      width: parent.width
      icon: section.icon
      label: section.title
      value: section.value
    }

    Item {
      id: holder
      x: 12
      width: parent.width - 24
      height: childrenRect.height
    }
  }

  Item {
    width: parent.width
    height: 48

    IconButton {
      id: backButton
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      icon: "arrow_back"
      onClicked: Displays.close()
    }

    Icon {
      id: heading
      anchors.left: backButton.right
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: "monitor"
      color: Theme.primary
      size: 28
    }

    Column {
      anchors.left: heading.right
      anchors.leftMargin: 12
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Label {
        width: parent.width
        text: "Displays"
        pixelSize: Theme.menuTitleSize
      }

      Label {
        width: parent.width
        text: Displays.outputs.length === 1 ? "1 connected" : Displays.outputs.length + " connected"
        color: Theme.textVariant
        pixelSize: Theme.menuSubtitleSize
      }
    }
  }

  DisplaysCanvas {
    width: parent.width
    visible: Displays.outputs.length > 1
  }

  TabBar {
    anchors.horizontalCenter: parent.horizontalCenter
    height: 38
    visible: Displays.outputs.length > 1
    model: Displays.outputs.map(o => ({
          id: o.name,
          name: o.name,
          icon: (Displays.draft[o.name]?.enabled ?? o.enabled) ? "monitor" : "desktop_access_disabled"
        }))
    current: Displays.selected
    onSelected: id => Displays.selected = id
  }

  Rectangle {
    width: parent.width
    height: card.implicitHeight + 16
    radius: Theme.menuItemRadius
    color: Theme.surfaceContainer
    visible: root.output !== null && root.current !== null

    Column {
      id: card
      y: 8
      width: parent.width
      spacing: 8

      InfoRow {
        width: parent.width
        icon: "info"
        label: root.output ? root.output.title : ""
        value: ""

        Switch {
          anchors.right: parent.right
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          checked: root.current?.enabled ?? false
          opacity: root.locked || (root.current?.enabled && Displays.enabledCount <= 1) ? 0.4 : 1
          onToggled: {
            if (root.locked || (root.current.enabled && Displays.enabledCount <= 1))
              return;
            Displays.update(root.output.name, {
              enabled: !root.current.enabled
            });
          }
        }
      }

      Collapse {
        width: parent.width
        shown: root.current?.enabled ?? false

        Column {
          width: parent.width
          spacing: 8

          Section {
            title: "Resolution"
            icon: "aspect_ratio"
            value: root.current ? `${root.current.width} × ${root.current.height}` : ""

            Flow {
              width: parent.width
              spacing: 6

              Repeater {
                model: root.resolutions

                Chip {
                  required property var modelData
                  text: `${modelData.width}×${modelData.height}`
                  selected: root.current && root.current.width === modelData.width && root.current.height === modelData.height
                  available: !root.locked
                  onClicked: Displays.setResolution(root.output.name, modelData.width, modelData.height)
                }
              }
            }
          }

          Section {
            title: "Refresh rate"
            icon: "speed"
            value: root.current ? root.hz(root.current.refresh) : ""

            Flow {
              width: parent.width
              spacing: 6

              Repeater {
                model: root.rates

                Chip {
                  required property int modelData
                  text: root.hz(modelData)
                  selected: root.current && root.current.refresh === modelData
                  available: !root.locked
                  onClicked: Displays.update(root.output.name, {
                    refresh: modelData
                  })
                }
              }
            }
          }

          InfoRow {
            width: parent.width
            icon: "zoom_in"
            label: "Scale"
            value: ""

            Row {
              anchors.right: parent.right
              anchors.rightMargin: 6
              anchors.verticalCenter: parent.verticalCenter
              spacing: 2

              IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "remove"
                opacity: !root.locked && root.current && root.current.scale > 0.5 ? 1 : 0.4
                onClicked: {
                  if (!root.locked && root.current.scale > 0.5)
                    Displays.update(root.output.name, {
                      scale: Math.round((root.current.scale - 0.25) * 4) / 4
                    });
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 64
                horizontalAlignment: Text.AlignHCenter
                text: root.current ? Math.round(root.current.scale * 100) + "%" : ""
                color: Theme.text
                font.family: Theme.labelFont
                font.pixelSize: Theme.menuSubtitleSize + 1
              }

              IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "add"
                opacity: !root.locked && root.current && root.current.scale < 3 ? 1 : 0.4
                onClicked: {
                  if (!root.locked && root.current.scale < 3)
                    Displays.update(root.output.name, {
                      scale: Math.round((root.current.scale + 0.25) * 4) / 4
                    });
                }
              }
            }
          }

          Section {
            title: "Rotation"
            icon: "screen_rotation"
            value: ""

            Row {
              spacing: 6

              Repeater {
                model: root.rotations

                Chip {
                  required property var modelData
                  text: modelData.label
                  selected: root.current && root.current.transform === modelData.value
                  available: !root.locked
                  onClicked: Displays.update(root.output.name, {
                    transform: modelData.value
                  })
                }
              }
            }
          }
        }
      }
    }
  }

  Text {
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    text: Displays.error !== "" ? Displays.error : Displays.dirty ? "Changes aren't applied yet" : "Changes are applied live, then kept or reverted"
    color: Displays.error !== "" ? Theme.error : Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuSubtitleSize - 1
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 8

    Chip {
      icon: "restart_alt"
      text: "Reset"
      available: Displays.dirty && !Displays.busy && !Displays.confirming
      onClicked: Displays.reset()
    }

    Chip {
      icon: "check"
      text: "Apply"
      selected: true
      available: Displays.dirty && !Displays.busy && !Displays.confirming && Displays.enabledCount > 0
      onClicked: Displays.apply()
    }
  }
}
