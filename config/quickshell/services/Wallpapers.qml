pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME")
  property string directory: home + "/Pictures/Wallpapers"
  readonly property string stateDir: home + "/.local/state/yurice"

  property list<string> wallpapers: []
  readonly property string current: state.path || (wallpapers.length > 0 ? wallpapers[0] : "")

  property bool pickerOpen: false
  property string coveredOutput: ""

  function expand(path) {
    return path.startsWith("~/") ? home + path.slice(1) : path;
  }

  function set(path) {
    path = expand(path);
    if (path === "" || path === current)
      return;
    state.path = path;
    stateFile.writeAdapter();
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
    function get(): string {
      return root.current;
    }
    function list(): string {
      return root.wallpapers.join("\n");
    }
  }
}
