pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property bool loaded: false

  readonly property string mode: state.mode === "normie" ? "normie" : "weeb"
  readonly property bool normie: mode === "normie"
  readonly property string label: normie ? "Normie" : "Weeb"
  readonly property string icon: normie ? "visibility_off" : "visibility"

  readonly property bool hidesWallpapers: normie && state.hideWallpapers
  readonly property bool hidesDanbooru: normie && state.hideDanbooru
  readonly property bool hidesAnimeFilter: normie && state.hideAnimeFilter
  readonly property bool hidesAdultFilters: normie && state.hideAdultFilters
  readonly property bool hidesAvatar: normie && state.hideAvatar

  function toggle() {
    set(normie ? "weeb" : "normie");
  }

  function set(next) {
    if (next !== "weeb" && next !== "normie")
      return;
    state.mode = next;
    file.writeAdapter();
  }

  function isHidden(name) {
    return state[name] === true;
  }

  function setHidden(name, on) {
    state[name] = on;
    file.writeAdapter();
  }

  FileView {
    id: file
    path: Quickshell.env("HOME") + "/.local/state/yurice/weeb.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loaded = true
    onLoadFailed: root.loaded = true

    JsonAdapter {
      id: state
      property string mode: "weeb"
      property bool hideWallpapers: true
      property bool hideDanbooru: true
      property bool hideAnimeFilter: true
      property bool hideAdultFilters: true
      property bool hideAvatar: true
    }
  }

  IpcHandler {
    target: "weeb"

    function toggle(): void {
      root.toggle();
    }
    function set(mode: string): void {
      root.set(mode);
    }
    function get(): string {
      return root.mode;
    }
  }
}
