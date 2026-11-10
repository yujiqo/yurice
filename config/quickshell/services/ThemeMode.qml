pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property bool auto: state.auto
  readonly property int lightStart: state.lightStart
  readonly property int lightEnd: state.lightEnd
  property bool loaded: false

  readonly property string scheduled: isLightAt(Clock.date) ? "light" : "dark"
  readonly property string mode: state.auto ? scheduled : state.mode
  readonly property string label: mode === "light" ? "Light" : "Dark"
  readonly property string icon: mode === "light" ? "light_mode" : "dark_mode"

  readonly property string status: {
    if (!state.auto)
      return "Automatic switching is off";
    const at = formatTime(nextSwitch(Clock.date));
    return `Switches to ${mode === "light" ? "dark" : "light"} at ${at}`;
  }

  function minutesOf(date) {
    return date.getHours() * 60 + date.getMinutes();
  }

  function isLightAt(date) {
    const now = minutesOf(date);
    const start = state.lightStart;
    const end = state.lightEnd;
    return start <= end ? now >= start && now < end : now >= start || now < end;
  }

  function nextSwitch(date) {
    const now = minutesOf(date);
    const delta = Math.min(...[state.lightStart, state.lightEnd].map(at => ((at - now + 1439) % 1440) + 1));
    const next = new Date(date.getTime() + delta * 60000);
    next.setSeconds(0, 0);
    return next;
  }

  function formatTime(date) {
    return Qt.formatTime(date, Clock.shortTimeFormat);
  }

  function formatMinutes(minutes) {
    return Qt.formatTime(new Date(2000, 0, 1, Math.floor(minutes / 60), minutes % 60), Clock.shortTimeFormat);
  }

  function toggle() {
    set(mode === "light" ? "dark" : "light");
  }

  function set(next) {
    if (next !== "light" && next !== "dark")
      return;
    state.mode = next;
    state.auto = false;
    file.writeAdapter();
  }

  function setAuto(on) {
    if (on === state.auto)
      return;
    state.mode = mode;
    state.auto = on;
    file.writeAdapter();
  }

  function adjust(name, step) {
    const other = name === "lightStart" ? state.lightEnd : state.lightStart;
    let next = (state[name] + step + 1440) % 1440;
    if (next === other)
      next = (next + step + 1440) % 1440;
    state[name] = next;
    file.writeAdapter();
  }

  function markApplied(applied) {
    if (state.applied !== applied) {
      state.applied = applied;
      file.writeAdapter();
    }
    sync();
  }

  function sync() {
    if (!loaded || !Wallpapers.ready || Wallpapers.current === "")
      return;
    if (state.applied !== mode)
      Wallpapers.generatePalette(Wallpapers.current);
  }

  function applyDesktop() {
    if (!loaded)
      return;
    const light = mode === "light";
    Quickshell.execDetached(["dconf", "write", "/org/gnome/desktop/interface/color-scheme", light ? "'prefer-light'" : "'prefer-dark'"]);
    Quickshell.execDetached(["dconf", "write", "/org/gnome/desktop/interface/gtk-theme", light ? "'adw-gtk3'" : "'adw-gtk3-dark'"]);
  }

  onModeChanged: {
    applyDesktop();
    sync();
  }
  onLoadedChanged: {
    applyDesktop();
    sync();
  }

  Connections {
    target: Wallpapers
    function onReadyChanged() {
      root.sync();
    }
    function onCurrentChanged() {
      root.sync();
    }
  }

  FileView {
    id: file
    path: Paths.state + "/theme.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loaded = true
    onLoadFailed: root.loaded = true

    JsonAdapter {
      id: state
      property bool auto: true
      property int lightStart: 480
      property int lightEnd: 960
      property string mode: "dark"
      property string applied: ""
    }
  }

  IpcHandler {
    target: "theme"

    function toggle(): void {
      root.toggle();
    }
    function set(mode: string): void {
      root.set(mode);
    }
    function get(): string {
      return root.mode;
    }
    function setAuto(on: bool): void {
      root.setAuto(on);
    }
  }
}
