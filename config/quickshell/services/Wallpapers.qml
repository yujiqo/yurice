pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import qs.theme

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string directory: Settings.wallpaperDirectory
  readonly property string stateDir: home + "/.local/state/yurice"
  readonly property string matugenConfig: Quickshell.shellDir + "/../matugen/config.toml"

  property bool stateLoaded: false
  property list<string> wallpapers: []
  readonly property string current: state.path || (wallpapers.length > 0 ? wallpapers[0] : "")
  property var resolutions: ({})

  readonly property size screenSize: {
    let w = 0;
    let h = 0;
    for (const s of Quickshell.screens) {
      w = Math.max(w, s.width * s.devicePixelRatio);
      h = Math.max(h, s.height * s.devicePixelRatio);
    }
    return Qt.size(Math.round(w), Math.round(h));
  }
  readonly property string screenResolution: `${screenSize.width}x${screenSize.height}`

  function resolutionOf(path) {
    const r = resolutions[path];
    return r && r.w > 0 ? `${r.w}x${r.h}` : "";
  }

  readonly property size upscaleTarget: Qt.size(3840, 2160)

  function canUpscale(path) {
    const r = resolutions[path];
    return !!r && r.w > 0 && (r.w < upscaleTarget.width || r.h < upscaleTarget.height);
  }

  function _measure() {
    const missing = wallpapers.filter(p => !resolutions[p]);
    if (missing.length === 0 || identify.running)
      return;
    identify.batch = missing;
    identify.command = ["magick", "identify", "-ping", "-format", "%w %h %i\\n"].concat(missing.map(p => p + "[0]"));
    identify.running = true;
  }

  function forgetResolution(path) {
    const next = Object.assign({}, resolutions);
    delete next[path];
    resolutions = next;
  }

  onWallpapersChanged: _measure()

  Process {
    id: identify
    property var batch: []
    stdout: StdioCollector {
      onStreamFinished: {
        const next = Object.assign({}, root.resolutions);
        for (const p of identify.batch)
          next[p] = {
            w: 0,
            h: 0
          };
        for (const line of text.split("\n")) {
          const m = line.match(/^(\d+) (\d+) (.+)$/);
          if (m)
            next[m[3]] = {
              w: parseInt(m[1]),
              h: parseInt(m[2])
            };
        }
        root.resolutions = next;
        Qt.callLater(root._measure);
      }
    }
  }

  property bool pickerOpen: false
  property string coveredOutput: ""

  property string _pendingPalette: ""
  property bool _paletteChecked: false

  function expand(path) {
    return path.startsWith("~/") ? home + path.slice(1) : path;
  }

  function set(path) {
    path = expand(path);
    if (path === "" || path === current)
      return;
    state.path = path;
    stateFile.writeAdapter();
    generatePalette(path);
  }

  function generatePalette(path) {
    if (path === "")
      return;
    if (matugen.running) {
      _pendingPalette = path;
      return;
    }
    matugen.mode = ThemeMode.mode;
    matugen.command = ["matugen", "image", path, "-c", matugenConfig, "-m", matugen.mode, "--source-color-index", "0", "-q"];
    matugen.running = true;
  }

  function _rebuild() {
    const list = [];
    for (let i = 0; i < folder.count; i++)
      list.push(folder.get(i, "filePath"));
    wallpapers = list;
  }

  FolderListModel {
    id: folder
    folder: "file://" + root.directory
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
    caseSensitive: false
    showDirs: false
    sortField: FolderListModel.Name
    onCountChanged: root._rebuild()
    onStatusChanged: if (status === FolderListModel.Ready)
      root._rebuild()
  }

  Process {
    running: true
    command: ["mkdir", "-p", root.stateDir]
  }

  Process {
    id: matugen
    property string mode: ""
    stderr: StdioCollector {
      id: matugenErr
    }
    onExited: exitCode => {
      if (exitCode !== 0)
        console.warn("Wallpapers: matugen failed:", matugenErr.text);
      else
        ThemeMode.markApplied(mode);
      Theme.reloadPalette();
      if (root._pendingPalette !== "") {
        const next = root._pendingPalette;
        root._pendingPalette = "";
        root.generatePalette(next);
      }
    }
  }

  Process {
    id: paletteCheck
    command: ["test", "-f", Theme.paletteFile]
    onExited: exitCode => {
      if (exitCode !== 0)
        root.generatePalette(root.current);
    }
  }

  function _checkPalette() {
    if (current === "" || _paletteChecked)
      return;
    _paletteChecked = true;
    paletteCheck.running = true;
  }

  onCurrentChanged: _checkPalette()
  Component.onCompleted: _checkPalette()

  FileView {
    id: stateFile
    path: root.stateDir + "/wallpaper.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.stateLoaded = true
    onLoadFailed: root.stateLoaded = true

    JsonAdapter {
      id: state
      property string path: ""
    }
  }

  IpcHandler {
    target: "wallpaper"

    function toggle(): void {
      root.pickerOpen = !root.pickerOpen;
    }
    function open(): void {
      root.pickerOpen = true;
    }
    function close(): void {
      root.pickerOpen = false;
    }
    function set(path: string): void {
      root.set(path);
    }
    function regenerate(): void {
      root.generatePalette(root.current);
    }
    function get(): string {
      return root.current;
    }
    function list(): string {
      return root.wallpapers.join("\n");
    }
  }
}
