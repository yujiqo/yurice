pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property var values: parse(file.text())
  readonly property string wallpaperDirectory: expandPath(values.wallpaperDirectory || "~/Pictures/Wallpapers")
  readonly property string danbooruDirectory: expandPath(values.danbooruDirectory || "~/Pictures/Danbooru")

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

  function expandPath(path) {
    return path.replace(/^~(?=\/|$)/, home);
  }

  function displayPath(path) {
    return path === home || path.startsWith(home + "/") ? "~" + path.slice(home.length) : path;
  }

  FileView {
    id: file
    path: root.home + "/.config/yurice/custom/quickshell/settings.json"
    blockLoading: true
    printErrors: false
  }
}
