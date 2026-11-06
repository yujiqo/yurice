pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import qs.theme

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME")
  property string directory: home + "/Pictures/Wallpapers"
  readonly property string stateDir: home + "/.local/state/yurice"
  readonly property string matugenConfig: Quickshell.shellDir + "/../matugen/config.toml"

  property list<string> wallpapers: []
  readonly property string current: state.path || (wallpapers.length > 0 ? wallpapers[0] : "")

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
    matugen.command = ["matugen", "image", path, "-c", matugenConfig, "--source-color-index", "0", "-q"];
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
    stderr: StdioCollector {
      id: matugenErr
    }
    onExited: exitCode => {
      if (exitCode !== 0)
        console.warn("Wallpapers: matugen failed:", matugenErr.text);
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
