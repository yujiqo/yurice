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
  readonly property string screenshotDirectory: expandPath(values.screenshotDirectory || "~/Pictures/Screenshots")
  readonly property string avatarPath: expandPath(values.avatar || "~/.config/yurice/custom/avatars/weeb.jpg")
  readonly property string normieAvatarPath: expandPath(values.normieAvatar || "~/.config/yurice/custom/avatars/normie.jpg")

  readonly property int idleScreenOff: values.idleScreenOff ?? 10
  readonly property int idleLockedScreenOff: values.idleLockedScreenOff ?? 1
  readonly property int idleLock: values.idleLock ?? 30
  readonly property int idleSuspend: values.idleSuspend ?? 5

  readonly property bool clock24h: values.clock24h ?? true
  readonly property bool clockSeconds: values.clockSeconds ?? false
  readonly property string shortTimeFormat: clock24h ? "HH:mm" : "h:mm AP"
  readonly property string timeFormat: clock24h ? (clockSeconds ? "HH:mm:ss" : "HH:mm") : (clockSeconds ? "h:mm:ss AP" : "h:mm AP")
  property string shownTimeFormat: ""
  property string shownShortTimeFormat: ""
  property bool shownClock24h: true
  property real timeFade: 1

  onTimeFormatChanged: timeSwap.restart()

  function showTimeFormat() {
    shownTimeFormat = timeFormat;
    shownShortTimeFormat = shortTimeFormat;
    shownClock24h = clock24h;
  }

  SequentialAnimation {
    id: timeSwap

    NumberAnimation {
      target: root
      property: "timeFade"
      to: 0
      duration: 180
      easing.type: Easing.InQuad
    }
    ScriptAction {
      script: root.showTimeFormat()
    }
    NumberAnimation {
      target: root
      property: "timeFade"
      to: 1
      duration: 250
      easing.type: Easing.OutQuad
    }
  }

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

  function expandPath(path) {
    return path.replace(/^~(?=\/|$)/, home);
  }

  function displayPath(path) {
    return path === home || path.startsWith(home + "/") ? "~" + path.slice(home.length) : path;
  }

  Component.onCompleted: {
    showTimeFormat();
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
