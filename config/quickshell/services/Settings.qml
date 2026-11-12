pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string directory: Paths.custom + "/quickshell"
  property var values: parse(file.text())
  readonly property string wallpaperDirectory: Paths.expand(values.wallpaperDirectory || "~/Pictures/Wallpapers")
  readonly property string danbooruDirectory: Paths.expand(values.danbooruDirectory || "~/Pictures/Danbooru")
  readonly property string screenshotDirectory: Paths.expand(values.screenshotDirectory || "~/Pictures/Screenshots")
  readonly property string avatarPath: Paths.expand(values.avatar || Paths.custom + "/avatars/weeb.jpg")
  readonly property string normieAvatarPath: Paths.expand(values.normieAvatar || Paths.custom + "/avatars/normie.jpg")

  readonly property int idleScreenOff: values.idleScreenOff ?? 10
  readonly property int idleLockedScreenOff: values.idleLockedScreenOff ?? 1
  readonly property int idleLock: values.idleLock ?? 30
  readonly property int idleSuspend: values.idleSuspend ?? 5

  readonly property bool clock24h: values.clock24h ?? true
  readonly property bool clockSeconds: values.clockSeconds ?? false
  readonly property string shortTimeFormat: clock24h ? "HH:mm" : "h:mm AP"
  readonly property string timeFormat: clock24h ? (clockSeconds ? "HH:mm:ss" : "HH:mm") : (clockSeconds ? "h:mm:ss AP" : "h:mm AP")

  readonly property var hiddenIslands: Array.isArray(values.hiddenIslands) ? values.hiddenIslands : []

  readonly property var weatherLocation: values.weatherLocation ?? null
  readonly property bool weatherFahrenheit: values.weatherFahrenheit ?? false

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

  Component.onCompleted: {
    Quickshell.execDetached(["mkdir", "-p", directory]);
  }

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
