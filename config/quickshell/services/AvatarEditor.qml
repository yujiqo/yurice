pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string mode: ""
  readonly property bool active: mode !== ""
  property string folder: Paths.home + "/Pictures"
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
    cropper.command = ["sh", Paths.scripts + "/crop-avatar.sh", file, target, left.toFixed(6), top.toFixed(6), side.toFixed(6)];
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
