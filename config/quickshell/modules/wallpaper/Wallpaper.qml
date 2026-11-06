import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.components
import qs.services

PanelWindow {
  id: root

  required property ShellScreen modelData
  screen: modelData

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Background
  WlrLayershell.namespace: "yurice-wallpaper"
  color: "transparent"

  readonly property size imageSize: Qt.size(modelData.width * modelData.devicePixelRatio, modelData.height * modelData.devicePixelRatio)
  readonly property string path: Wallpapers.current

  property Image front: a
  readonly property Image back: front === a ? b : a

  onPathChanged: load()
  Component.onCompleted: load()

  function load() {
    if (fade.running) {
      fade.stop();
      swap();
    }
    if (path === "" || front.path === path)
      return;
    back.path = path;
    startFade(back);
  }

  function startFade(img) {
    if (img !== back || img.status !== Image.Ready || img.path !== path)
      return;
    back.z = 1;
    front.z = 0;
    fade.target = back;
    fade.start();
  }

  function swap() {
    const old = front;
    front = back;
    front.opacity = 1;
    old.opacity = 0;
    old.path = "";
  }

  NumberAnimation {
    id: fade
    property: "opacity"
    from: 0
    to: 1
    duration: Theme.animWallpaper
    easing.type: Theme.easeOut
    onFinished: root.swap()
  }

  component WallpaperImage: Image {
    property string path: ""
    source: Utility.fileUrl(path)
    anchors.fill: parent
    opacity: 0
    fillMode: Image.PreserveAspectCrop
    sourceSize: root.imageSize
    asynchronous: true
    cache: false
    smooth: true
    onStatusChanged: root.startFade(this)
  }

  WallpaperImage {
    id: a
  }
  WallpaperImage {
    id: b
  }
}
