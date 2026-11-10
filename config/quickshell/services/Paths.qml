pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

Singleton {
  readonly property string home: Quickshell.env("HOME")
  readonly property string config: home + "/.config/yurice"
  readonly property string custom: config + "/custom"
  readonly property string state: home + "/.local/state/yurice"
  readonly property string cache: home + "/.cache/yurice"
  readonly property string shared: Quickshell.env("YURICE_STATE_ROOT") || "/var/lib/yurice"
  readonly property string scripts: Quickshell.shellDir + "/scripts"

  function expand(path) {
    return path.replace(/^~(?=\/|$)/, home);
  }

  function display(path) {
    return path === home || path.startsWith(home + "/") ? "~" + path.slice(home.length) : path;
  }

  function fileUrl(path) {
    if (!path)
      return "";
    return "file://" + path.split("/").map(encodeURIComponent).join("/");
  }

  function baseName(path) {
    return path.slice(path.lastIndexOf("/") + 1);
  }

  function dirName(path) {
    return path.slice(0, Math.max(0, path.lastIndexOf("/")));
  }

  Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", state, cache])
}
