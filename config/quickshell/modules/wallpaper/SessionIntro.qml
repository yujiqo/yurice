import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.theme
import qs.services

Scope {
  id: root

  property bool active: false
  property real reveal: 0
  property real cover: 1
  property var readyScreens: ({})

  function screenReady(name) {
    const next = Object.assign({}, readyScreens);
    next[name] = true;
    readyScreens = next;
    if (Quickshell.screens.every(screen => readyScreens[screen.name]))
      begin();
  }

  function begin() {
    if (!active || anim.running)
      return;
    timeout.stop();
    anim.start();
  }

  Component.onCompleted: {
    if (marker.text().trim() === "done" || SessionLock.phase !== "idle")
      return;
    marker.setText("done");
    active = true;
    timeout.start();
  }

  Timer {
    id: timeout
    interval: 3000
    onTriggered: root.begin()
  }

  SequentialAnimation {
    id: anim

    NumberAnimation {
      target: root
      property: "reveal"
      to: 1
      duration: Theme.animLock + 250
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root
      property: "cover"
      to: 0
      duration: Theme.animMove
      easing.type: Theme.easeOut
    }
    ScriptAction {
      script: root.active = false
    }
  }

  FileView {
    id: marker
    path: `${Quickshell.env("XDG_RUNTIME_DIR")}/yurice-intro-${Quickshell.env("WAYLAND_DISPLAY")}`
    blockLoading: true
    blockWrites: true
    printErrors: false
  }

  Variants {
    model: root.active ? Quickshell.screens : []

    PanelWindow {
      id: window

      required property ShellScreen modelData
      screen: modelData

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "yurice-session-intro"
      color: "transparent"
      mask: Region {}

      Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.cover

        Image {
          id: image
          anchors.fill: parent
          source: Wallpapers.ready && WallpaperPublish.displayFile !== "" ? "file://" + WallpaperPublish.displayFile : ""
          sourceSize: Qt.size(window.modelData.width * window.modelData.devicePixelRatio, window.modelData.height * window.modelData.devicePixelRatio)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
          visible: false
          onStatusChanged: {
            if (status === Image.Ready || status === Image.Error)
              root.screenReady(window.modelData.name);
          }
        }

        MultiEffect {
          anchors.fill: parent
          source: image
          visible: image.status === Image.Ready
          blurEnabled: true
          blurMax: 64
          blur: 1 - root.reveal
          opacity: root.reveal
          scale: 1 + Theme.lockZoom * (1 - root.reveal)
        }
      }
    }
  }
}
