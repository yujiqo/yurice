pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

PanelWindow {
  id: root

  required property ShellScreen modelData
  screen: modelData
  visible: SessionLock.phase === "capturing"

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "yurice-lock-snapshot"
  color: "transparent"
  mask: Region {}

  Loader {
    anchors.fill: parent
    active: root.visible

    sourceComponent: ScreencopyView {
      id: view

      captureSource: root.modelData
      live: false
      paintCursor: false
      onHasContentChanged: {
        if (!hasContent)
          return;
        const ratio = root.modelData.devicePixelRatio;
        view.grabToImage(result => SessionLock.snapshotReady(root.modelData.name, result.url), Qt.size(width * ratio, height * ratio));
      }
    }
  }
}
