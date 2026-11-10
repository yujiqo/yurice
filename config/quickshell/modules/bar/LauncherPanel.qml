import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  property string query: ""
  readonly property bool hasCalc: Launcher.calcResult !== ""
  readonly property var results: Launcher.apps(query)
  readonly property var rows: (hasCalc ? [
      {
        kind: "calc"
      }
    ] : []).concat(results.slice(0, 50).map(e => ({
        kind: "app",
        entry: e
      })))

  spacing: Theme.menuGap

  Component.onCompleted: Qt.callLater(field.focusInput)

  function activate(index) {
    const row = rows[index];
    if (!row)
      return;
    if (row.kind === "calc")
      Launcher.copyResult();
    else
      Launcher.launch(row.entry);
  }

  TextField {
    id: field
    width: parent.width
    leadingIcon: "search"
    placeholder: "Search apps or calculate…"
    onTextChanged: {
      root.query = text;
      Launcher.calculate(text);
      list.currentIndex = 0;
    }
    onNavigate: delta => list.currentIndex = Math.max(0, Math.min(root.rows.length - 1, list.currentIndex + delta))
    onAccepted: root.activate(list.currentIndex)
  }

  Text {
    width: parent.width
    height: Theme.menuItemHeight
    visible: root.rows.length === 0
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: "No results"
    color: Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuTitleSize
  }

  ListView {
    id: list
    width: parent.width
    height: Math.min(contentHeight, Theme.menuListMaxHeight)
    visible: root.rows.length > 0
    clip: true
    spacing: Theme.menuGap
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    model: root.rows
    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

    delegate: MenuItem {
      id: appRow

      required property var modelData
      required property int index
      readonly property bool isCalc: modelData.kind === "calc"
      readonly property string iconName: isCalc ? "" : (modelData.entry?.icon ?? "")

      width: list.width
      active: index === list.currentIndex
      icon: isCalc ? "calculate" : "apps"
      title: isCalc ? "= " + Launcher.calcResult : modelData.entry.name
      subtitle: isCalc ? Launcher.calcQuery + " · Enter to copy" : (modelData.entry.genericName || modelData.entry.comment || "")
      leading: isCalc ? null : appIcon
      onClicked: root.activate(index)

      Component {
        id: appIcon

        Rectangle {
          readonly property string source: Launcher.iconFor(appRow.iconName)
          readonly property bool hasIcon: source !== "" && image.status !== Image.Error

          implicitWidth: 36
          implicitHeight: 36
          radius: 11
          color: hasIcon ? Theme.surfaceContainerHighest : Theme.primaryContainer

          IconImage {
            id: image
            anchors.centerIn: parent
            implicitSize: 26
            asynchronous: true
            source: parent.source
            visible: parent.hasIcon
          }

          Text {
            anchors.centerIn: parent
            visible: !parent.hasIcon
            text: (appRow.modelData.entry?.name ?? "?").charAt(0).toUpperCase()
            color: Theme.textOnPrimaryContainer
            font.family: Theme.labelFont
            font.pixelSize: 18
            font.bold: true
          }
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: appRow.active
        rightPadding: 6
        text: "↵"
        color: Theme.textOnPrimary
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuTitleSize
      }
    }
  }
}
