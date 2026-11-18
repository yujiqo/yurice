pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import qs.theme

Singleton {
  id: root

  readonly property string directory: Settings.wallpaperDirectory
  readonly property string matugenConfig: Quickshell.shellDir + "/../matugen/config.toml"

  property bool stateLoaded: false
  property bool safeLoaded: false
  property var safeFiles: ({})
  readonly property bool ready: stateLoaded && safeLoaded && WeebMode.loaded
  readonly property bool hideUnsafe: WeebMode.hidesWallpapers
  readonly property int safeCount: allWallpapers.filter(path => isSafe(path)).length

  property list<string> allWallpapers: []
  readonly property list<string> wallpapers: !ready ? [] : hideUnsafe ? allWallpapers.filter(path => isSafe(path)) : allWallpapers
  readonly property string current: {
    if (!ready)
      return "";
    if (!hideUnsafe)
      return state.path || (allWallpapers.length > 0 ? allWallpapers[0] : "");
    if (state.normiePath !== "" && isSafe(state.normiePath))
      return state.normiePath;
    return wallpapers.length > 0 ? wallpapers[0] : "";
  }
  property var resolutions: ({})
  property bool pickerOpen: false
  property string coveredOutput: ""
  property string pendingPalette: ""
  property bool paletteChecked: false
  readonly property size upscaleTarget: Qt.size(3840, 2160)
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
  readonly property string thumbDir: Paths.cache + "/wallpaper-thumbs"
  readonly property size thumbSize: {
    if (screenSize.height <= 0)
      return Qt.size(0, 0);
    const h = Math.max(Math.round(screenSize.height * Theme.pickerScale * Theme.pickerThumbOversample), Theme.pickerThumbMinHeight);
    return Qt.size(Math.round(h * screenSize.width / screenSize.height), h);
  }
  property var modified: ({})
  property var thumbs: ({})
  property bool thumbsDirty: false

  function thumbPath(path) {
    const key = `${path}|${modified[path] ?? 0}|${thumbSize.width}x${thumbSize.height}`;
    return `${thumbDir}/${Qt.md5(key)}.jpg`;
  }

  function thumbFor(path) {
    if (!path)
      return "";
    const file = thumbPath(path);
    return thumbs[file] ? Paths.fileUrl(file) : "";
  }

  function makeThumbs() {
    if (allWallpapers.length === 0 || thumbSize.width <= 0)
      return;
    if (thumbGen.running) {
      thumbsDirty = true;
      return;
    }
    const args = [];
    for (const p of allWallpapers)
      args.push(p, thumbPath(p));
    thumbGen.command = ["sh", Paths.scripts + "/wallpaper-thumbs.sh", `${thumbSize.width}x${thumbSize.height}`, thumbDir].concat(args);
    thumbGen.running = true;
  }

  onThumbSizeChanged: thumbDebounce.restart()

  Timer {
    id: thumbDebounce
    interval: 300
    onTriggered: root.makeThumbs()
  }

  Process {
    id: thumbGen
    stdout: SplitParser {
      onRead: line => {
        if (line === "")
          return;
        const next = Object.assign({}, root.thumbs);
        next[line] = true;
        root.thumbs = next;
      }
    }
    onExited: () => {
      if (root.thumbsDirty) {
        root.thumbsDirty = false;
        root.makeThumbs();
      }
    }
  }

  function isSafe(path) {
    return safeFiles[Paths.baseName(path)] === true;
  }

  function setSafe(path, on) {
    const next = Object.assign({}, safeFiles);
    if (on)
      next[Paths.baseName(path)] = true;
    else
      delete next[Paths.baseName(path)];
    safeFiles = next;
    safeFile.setText(JSON.stringify(next, null, 2));
  }

  function readSafe() {
    try {
      safeFiles = JSON.parse(safeFile.text());
    } catch (e) {
      safeFiles = {};
    }
    safeLoaded = true;
  }

  function toggleSafe(path) {
    setSafe(path, !isSafe(path));
  }

  function moveSafe(from, to) {
    const wasSafe = isSafe(from);
    setSafe(from, false);
    if (wasSafe)
      setSafe(to, true);
  }

  function syncPalette() {
    if (ready && current !== "" && current !== state.palette)
      generatePalette(current);
  }

  onHideUnsafeChanged: pickerOpen = false
  onReadyChanged: {
    checkPalette();
    syncPalette();
  }

  function resolutionOf(path) {
    const r = resolutions[path];
    return r && r.w > 0 ? `${r.w}x${r.h}` : "";
  }

  function canUpscale(path) {
    const r = resolutions[path];
    return !!r && r.w > 0 && (r.w < upscaleTarget.width || r.h < upscaleTarget.height);
  }

  function measure() {
    const missing = allWallpapers.filter(p => !resolutions[p]);
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

  onAllWallpapersChanged: {
    measure();
    thumbDebounce.restart();
  }

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
        Qt.callLater(root.measure);
      }
    }
  }

  function set(path) {
    path = Paths.expand(path);
    if (path === "" || path === current)
      return;
    if (hideUnsafe && !isSafe(path))
      return;
    if (hideUnsafe)
      state.normiePath = path;
    else
      state.path = path;
    stateFile.writeAdapter();
  }

  function generatePalette(path) {
    if (path === "")
      return;
    if (matugen.running) {
      pendingPalette = path;
      return;
    }
    matugen.path = path;
    matugen.mode = ThemeMode.mode;
    matugen.command = ["matugen", "image", path, "-c", matugenConfig, "-m", matugen.mode, "--source-color-index", "0", "-q"];
    matugen.running = true;
  }

  function rebuild() {
    const list = [];
    const times = {};
    for (let i = 0; i < folder.count; i++) {
      const path = folder.get(i, "filePath");
      const date = folder.get(i, "fileModified");
      list.push(path);
      times[path] = date ? date.getTime() : 0;
    }
    modified = times;
    allWallpapers = list;
  }

  FolderListModel {
    id: folder
    folder: Paths.fileUrl(root.directory)
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
    caseSensitive: false
    showDirs: false
    sortField: FolderListModel.Name
    onCountChanged: root.rebuild()
    onStatusChanged: if (status === FolderListModel.Ready)
      root.rebuild()
  }

  Process {
    id: matugen
    property string mode: ""
    property string path: ""
    stderr: StdioCollector {
      id: matugenErr
    }
    onExited: exitCode => {
      if (exitCode !== 0) {
        console.warn("Wallpapers: matugen failed:", matugenErr.text);
      } else {
        state.palette = path;
        stateFile.writeAdapter();
        ThemeMode.markApplied(mode);
      }
      Theme.reloadPalette();
      if (root.pendingPalette !== "") {
        const next = root.pendingPalette;
        root.pendingPalette = "";
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

  function checkPalette() {
    if (current === "" || paletteChecked)
      return;
    paletteChecked = true;
    paletteCheck.running = true;
  }

  onCurrentChanged: {
    checkPalette();
    syncPalette();
  }
  Component.onCompleted: checkPalette()

  FileView {
    id: stateFile
    path: Paths.state + "/wallpaper.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.stateLoaded = true
    onLoadFailed: root.stateLoaded = true

    JsonAdapter {
      id: state
      property string path: ""
      property string normiePath: ""
      property string palette: ""
    }
  }

  FileView {
    id: safeFile
    path: Paths.state + "/wallpaper-safe.json"
    blockWrites: true
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.readSafe()
    onLoadFailed: root.safeLoaded = true
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
