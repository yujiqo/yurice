pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

Singleton {
  id: root

  readonly property string cacheFile: Paths.cache + "/wallpaper-cache.jpg"
  readonly property string publishDir: `${Paths.shared}/users/${Session.userName}`
  readonly property string avatar: WeebMode.avatar
  readonly property string cachedFor: cachePath.text().trim()
  readonly property string displayFile: Wallpapers.current !== "" && Wallpapers.current === cachedFor ? cacheFile : Wallpapers.current
  property bool pending: false

  function schedule() {
    if (Wallpapers.ready)
      debounce.restart();
  }

  function run() {
    if (publisher.running) {
      pending = true;
      return;
    }
    const size = Wallpapers.screenSize;
    publisher.command = ["sh", Paths.scripts + "/publish-wallpaper.sh", Wallpapers.current, avatar, Theme.paletteFile, `${size.width}x${size.height}`, cacheFile, publishDir];
    publisher.running = true;
  }

  Connections {
    target: Wallpapers
    function onCurrentChanged() {
      root.schedule();
    }
    function onReadyChanged() {
      root.schedule();
    }
    function onScreenSizeChanged() {
      root.schedule();
    }
  }

  Connections {
    target: Theme
    function onSurfaceChanged() {
      root.schedule();
    }
    function onPrimaryChanged() {
      root.schedule();
    }
  }

  onAvatarChanged: schedule()

  Timer {
    id: debounce
    interval: 1000
    onTriggered: root.run()
  }

  Process {
    id: publisher
    onExited: {
      cachePath.reload();
      if (root.pending) {
        root.pending = false;
        root.run();
      }
    }
  }

  FileView {
    id: cachePath
    path: root.cacheFile + ".path"
    blockLoading: true
    printErrors: false
  }
}
