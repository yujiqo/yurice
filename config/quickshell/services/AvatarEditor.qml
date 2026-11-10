pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string script: '
    src="$1"; out="$2"; x="$3"; y="$4"; side="$5"
    mkdir -p "$(dirname "$out")" || exit 1
    dims=$(magick "$src[0]" -auto-orient -format "%w %h" info:) || exit 1
    geo=$(echo "$dims" | awk -v x="$x" -v y="$y" -v s="$side" "{ w = \\$1; h = \\$2; n = int(s * w + 0.5); printf \\"%dx%d+%d+%d\\", n, n, int(x * w + 0.5), int(y * h + 0.5) }")
    tmp="${out%.*}.tmp.${out##*.}"
    magick "$src[0]" -auto-orient -crop "$geo" +repage -resize "512x512!" -strip -quality 92 "$tmp" || { rm -f "$tmp"; exit 1; }
    mv "$tmp" "$out"
  '

  property string mode: ""
  readonly property bool active: mode !== ""
  property string folder: Quickshell.env("HOME") + "/Pictures"
  property string file: ""
  property bool saving: false
  property string error: ""
  readonly property real revision: Settings.values.avatarRevision ?? 0
  readonly property string target: mode === "normie" ? Settings.normieAvatarPath : Settings.avatarPath

  function open(next) {
    mode = next;
    file = "";
    error = "";
  }

  function close() {
    mode = "";
    file = "";
    error = "";
  }

  function pick(path) {
    file = path;
    error = "";
  }

  function back() {
    file = "";
    error = "";
  }

  function navigate(path) {
    folder = path.length > 1 ? path.replace(/\/+$/, "") : path;
  }

  function parentFolder() {
    const index = folder.lastIndexOf("/");
    navigate(index <= 0 ? "/" : folder.slice(0, index));
  }

  function save(left, top, side) {
    if (saving || file === "")
      return;
    saving = true;
    error = "";
    cropper.command = ["sh", "-c", script, "sh", file, target, left.toFixed(6), top.toFixed(6), side.toFixed(6)];
    cropper.running = true;
  }

  Process {
    id: cropper
    stderr: StdioCollector {
      id: cropErrors
    }
    onExited: code => {
      root.saving = false;
      if (code !== 0) {
        root.error = "Couldn't save the picture";
        console.warn("AvatarEditor:", cropErrors.text.trim());
        return;
      }
      Settings.set("avatarRevision", Date.now());
      WallpaperPublish.schedule();
      root.close();
    }
  }
}
