pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property bool loaded: false

  readonly property string mode: state.mode === "normie" ? "normie" : "weeb"
  readonly property bool normie: mode === "normie"
  readonly property string primaryLabel: state.primaryName.trim() || "Weeb"
  readonly property string secondaryLabel: state.secondaryName.trim() || "Normie"
  readonly property string primaryIcon: "visibility"
  readonly property string secondaryIcon: "visibility_off"
  readonly property string label: labelFor(mode)
  readonly property string icon: iconFor(mode)

  readonly property bool hidesWallpapers: normie && state.hideWallpapers
  readonly property bool hidesDanbooru: hidesIsland("danbooru")
  readonly property bool hidesAnimeFilter: normie && state.hideAnimeFilter
  readonly property bool hidesAdultFilters: normie && state.hideAdultFilters
  readonly property bool hidesAvatar: normie && state.hideAvatar
  readonly property string avatar: hidesAvatar ? Settings.normieAvatarPath : Settings.avatarPath

  function labelFor(id) {
    return id === "normie" ? secondaryLabel : primaryLabel;
  }

  function iconFor(id) {
    return id === "normie" ? secondaryIcon : primaryIcon;
  }

  function name(id) {
    return id === "normie" ? state.secondaryName : state.primaryName;
  }

  function setName(id, value) {
    const next = value.trim().slice(0, 16);
    if (id === "normie")
      state.secondaryName = next;
    else
      state.primaryName = next;
    file.writeAdapter();
  }

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

  function islandHidden(id) {
    if (id === "danbooru")
      return state.hideDanbooru;
    return Array.from(state.hideIslands).includes(id);
  }

  function hidesIsland(id) {
    return normie && islandHidden(id);
  }

  function setIslandHidden(id, on) {
    if (id === "danbooru") {
      state.hideDanbooru = on;
    } else {
      const rest = Array.from(state.hideIslands).filter(other => other !== id);
      state.hideIslands = on ? rest.concat([id]) : rest;
    }
    file.writeAdapter();
  }

  FileView {
    id: file
    path: Paths.state + "/weeb.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loaded = true
    onLoadFailed: root.loaded = true

    JsonAdapter {
      id: state
      property string mode: "weeb"
      property string primaryName: ""
      property string secondaryName: ""
      property bool hideWallpapers: true
      property bool hideDanbooru: true
      property bool hideAnimeFilter: true
      property bool hideAdultFilters: true
      property bool hideAvatar: true
      property list<string> hideIslands: []
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
