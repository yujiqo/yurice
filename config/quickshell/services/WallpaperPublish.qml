pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

Singleton {
  id: root

  readonly property string script: '
    wall="$1"; avatar="$2"; colors="$3"; size="$4"; cache="$5"; dir="$6"
    mkdir -p "$(dirname "$cache")"
    if [ -f "$wall" ] && [ "$(cat "$cache.path" 2>/dev/null)" != "$wall" ]; then
      magick "$wall[0]" -resize "$size^" -strip -quality 95 "$cache.tmp.jpg" || exit 1
      mv "$cache.tmp.jpg" "$cache"
      printf %s "$wall" > "$cache.path"
    fi
    [ -d "$dir" ] && [ -w "$dir" ] || exit 0
    if [ -f "$wall" ] && [ -f "$cache" ]; then
      cp "$cache" "$dir/.wallpaper.tmp" && mv "$dir/.wallpaper.tmp" "$dir/wallpaper.jpg"
    else
      rm -f "$dir/wallpaper.jpg"
    fi
    if [ -f "$avatar" ]; then
      magick "$avatar[0]" -resize "256x256^" -strip -quality 92 "$dir/.avatar.tmp.jpg" && mv "$dir/.avatar.tmp.jpg" "$dir/avatar.jpg"
    else
      rm -f "$dir/avatar.jpg"
    fi
    [ -f "$colors" ] && cp "$colors" "$dir/.colors.tmp" && mv "$dir/.colors.tmp" "$dir/colors.json"
    chmod 644 "$dir"/wallpaper.jpg "$dir"/avatar.jpg "$dir"/colors.json 2>/dev/null
    exit 0
  '

  readonly property string cacheFile: Quickshell.env("HOME") + "/.cache/yurice/wallpaper-cache.jpg"
  readonly property string publishDir: `${Quickshell.env("YURICE_STATE_ROOT") || "/var/lib/yurice"}/users/${Quickshell.env("USER")}`
  readonly property string avatar: WeebMode.hidesAvatar ? Settings.normieAvatarPath : Settings.avatarPath
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
    publisher.command = ["sh", "-c", script, "sh", Wallpapers.current, avatar, Theme.paletteFile, `${size.width}x${size.height}`, cacheFile, publishDir];
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
