pragma ComponentBehavior: Bound
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

  readonly property size imageSize: Utility.pixelSize(modelData)
  readonly property string path: Wallpapers.current

  property WallpaperImage front: a
  readonly property WallpaperImage back: front === a ? b : a

  onPathChanged: load()
  Component.onCompleted: load()

  function load() {
    if (fade.running) {
      fade.stop();
      swap();
    }
    if (path === "" || front.path === path)
      return;
    back.file = path === WallpaperPublish.cachedFor ? WallpaperPublish.cacheFile : path;
    back.path = path;
    startFade(back);
  }

  function startFade(img) {
    if (img !== back || img.status !== Image.Ready || img.path !== path)
      return;
    back.z = 1;
    front.z = 0;
    if (modelData.name === Wallpapers.coveredOutput) {
      swap();
      return;
    }
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

  function clearImages() {
    if (path !== "" || blank.opacity < 1)
      return;
    fade.stop();
    for (const image of [a, b]) {
      image.opacity = 0;
      image.path = "";
    }
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
    id: image

    property string path: ""
    property string file: ""
    source: path === "" ? "" : Paths.fileUrl(file)
    anchors.fill: parent
    opacity: 0
    fillMode: Image.PreserveAspectCrop
    sourceSize: root.imageSize
    asynchronous: true
    cache: true
    smooth: true
    onStatusChanged: root.startFade(image)
  }

  WallpaperImage {
    id: a
  }
  WallpaperImage {
    id: b
  }

  Rectangle {
    id: blank
    anchors.fill: parent
    z: 2
    color: Theme.surfaceContainerHigh
    opacity: Wallpapers.ready && root.path === "" ? 1 : 0
    onOpacityChanged: root.clearImages()

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.animWallpaper
        easing.type: Theme.easeOut
      }
    }
  }
}
