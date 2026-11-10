pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string directory: home + "/.config/yurice/custom/quickshell"
  property var values: parse(file.text())
  readonly property string wallpaperDirectory: expandPath(values.wallpaperDirectory || "~/Pictures/Wallpapers")
  readonly property string danbooruDirectory: expandPath(values.danbooruDirectory || "~/Pictures/Danbooru")
  readonly property string avatarPath: expandPath(values.avatar || "~/.config/yurice/custom/avatars/weeb.jpg")
  readonly property string normieAvatarPath: expandPath(values.normieAvatar || "~/.config/yurice/custom/avatars/normie.jpg")

  readonly property int idleScreenOff: values.idleScreenOff ?? 10
  readonly property int idleLockedScreenOff: values.idleLockedScreenOff ?? 1
  readonly property int idleLock: values.idleLock ?? 30
  readonly property int idleSuspend: values.idleSuspend ?? 5

  function parse(text) {
    if (text.trim() === "")
      return {};
    try {
      return JSON.parse(text);
    } catch (e) {
      console.warn("Settings: invalid settings.json:", e.message);
      return {};
    }
  }

  function set(key, value) {
    const next = Object.assign({}, values);
    next[key] = value;
    values = next;
    file.setText(JSON.stringify(next, null, 2) + "\n");
  }

  function expandPath(path) {
    return path.replace(/^~(?=\/|$)/, home);
  }

  function displayPath(path) {
    return path === home || path.startsWith(home + "/") ? "~" + path.slice(home.length) : path;
  }

  Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", directory])

  FileView {
    id: file
    path: root.directory + "/settings.json"
    blockLoading: true
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.values = root.parse(text())
  }
}
