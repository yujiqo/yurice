import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  property string query: ""
  readonly property var rows: {
    const q = query.trim().toLowerCase();
    if (q === "")
      return Launcher.clips;
    return Launcher.clips.filter(c => !c.isImage && c.preview.toLowerCase().includes(q));
  }

  spacing: Theme.menuGap

  Component.onCompleted: {
    Launcher.loadClips();
    Qt.callLater(field.focusInput);
  }

  TextField {
    id: field
    width: parent.width
    leadingIcon: "content_paste"
    placeholder: "Search clipboard…"
    onTextChanged: {
      root.query = text;
      list.currentIndex = 0;
    }
    onNavigate: delta => list.currentIndex = Math.max(0, Math.min(root.rows.length - 1, list.currentIndex + delta))
    onAccepted: {
      const clip = root.rows[list.currentIndex];
      if (clip)
        Launcher.paste(clip);
    }
    onKeyPressed: event => {
      if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
        const clip = root.rows[list.currentIndex];
        if (clip)
          Launcher.remove(clip);
        event.accepted = true;
      }
    }
  }

  Item {
    width: parent.width
    height: Theme.menuItemHeight
    visible: root.rows.length === 0

    Spinner {
      anchors.centerIn: parent
      visible: Launcher.clipsLoading
    }

    Text {
      anchors.fill: parent
      visible: !Launcher.clipsLoading
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      text: root.query === "" ? "Clipboard history is empty" : "Nothing matches"
      color: Theme.textVariant
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuTitleSize
    }
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
      id: clipRow

      required property var modelData
      required property int index

      width: list.width
      implicitHeight: modelData.isImage ? 72 : Theme.menuItemHeight
      active: index === list.currentIndex
      icon: modelData.isImage ? "image" : "notes"
      title: modelData.isImage ? "Image" : modelData.preview.replace(/\s+/g, " ").trim()
      subtitle: modelData.isImage ? `${modelData.ext.toUpperCase()} · ${modelData.size}` : ""
      leading: modelData.isImage ? imageThumb : null
      onClicked: Launcher.paste(modelData)

      Component {
        id: imageThumb

        Rectangle {
          width: 84
          height: 56
          radius: 10
          color: Theme.surfaceContainerHighest

          RoundedImage {
            anchors.fill: parent
            radius: 10
            source: {
              const path = Launcher.thumbs[clipRow.modelData.id] ?? Launcher.thumb(clipRow.modelData);
              return path ? Utility.fileUrl(path) : "";
            }
            sourceSize: Qt.size(168, 112)
          }
        }
      }

      IconButton {
        icon: "close"
        iconColor: clipRow.active ? Theme.textOnPrimary : Theme.textVariant
        onClicked: Launcher.remove(clipRow.modelData)
      }
    }
  }
}
