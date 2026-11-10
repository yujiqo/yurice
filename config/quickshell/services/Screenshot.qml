pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string folder: Quickshell.env("HOME") + "/Pictures/Screenshots"
  readonly property string clipFile: Quickshell.cacheDir + "/screenshot.png"

  property string phase: ""
  property string output: ""
  property bool showPointer: false
  property bool busy: false
  property var ready: ({})
  property var overlays: ({})
  property date takenAt: new Date()

  property string selOutput: ""
  property real selX: 0
  property real selY: 0
  property real selW: 0
  property real selH: 0
  readonly property bool hasSelection: selOutput !== "" && selW >= 2 && selH >= 2
  readonly property bool selecting: phase === "selecting"
  readonly property bool closing: phase === "closing"

  function start() {
    if (phase !== "")
      return;
    output = Niri.focusedOutput || (Quickshell.screens[0]?.name ?? "");
    takenAt = new Date();
    showPointer = false;
    busy = false;
    ready = {};
    clearSelection();
    Quickshell.execDetached(["mkdir", "-p", folder]);
    phase = "capturing";
    fallback.restart();
  }

  function cancel() {
    fallback.stop();
    if (phase !== "selecting")
      return closed();
    phase = "closing";
    closeFallback.restart();
  }

  function closed() {
    closeFallback.stop();
    phase = "";
    busy = false;
    clearSelection();
  }

  function markReady(name) {
    if (phase !== "capturing")
      return;
    const next = Object.assign({}, ready);
    next[name] = true;
    ready = next;
    if (Quickshell.screens.every(s => ready[s.name]))
      begin();
  }

  function begin() {
    fallback.stop();
    if (phase === "capturing")
      phase = "selecting";
  }

  function register(name, overlay) {
    const next = Object.assign({}, overlays);
    if (overlay)
      next[name] = overlay;
    else
      delete next[name];
    overlays = next;
  }

  function clearSelection() {
    selOutput = "";
    selX = selY = selW = selH = 0;
  }

  function setSelection(name, x, y, w, h) {
    selOutput = name;
    selX = x;
    selY = y;
    selW = w;
    selH = h;
  }

  function fileName() {
    return folder + "/Screenshot from " + Qt.formatDateTime(takenAt, "yyyy-MM-dd HH-mm-ss") + ".png";
  }

  function shortPath(path) {
    return path.replace(Quickshell.env("HOME"), "~");
  }

  function finish(symbol, summary, body) {
    cancel();
    Notifications.notifyLocal("screenshot", symbol, summary, body, 3000);
  }

  function fail() {
    finish("error", "Screenshot failed", "Couldn't write the image");
  }

  function copy() {
    const overlay = overlays[selOutput];
    if (!selecting || busy || !hasSelection || !overlay)
      return;
    busy = true;
    overlay.grabRegion(result => {
      if (!result.saveToFile(root.clipFile))
        return root.fail();
      Quickshell.execDetached(["sh", "-c", "wl-copy --type image/png < \"$1\"", "sh", root.clipFile]);
      root.finish("content_copy", "Copied to clipboard", Math.round(root.selW) + " × " + Math.round(root.selH));
    });
  }

  function saveRegion() {
    const overlay = overlays[selOutput];
    if (!selecting || busy || !hasSelection || !overlay)
      return;
    busy = true;
    const path = fileName();
    overlay.grabRegion(result => {
      if (!result.saveToFile(path))
        return root.fail();
      root.finish("screenshot_region", "Region saved", root.shortPath(path));
    });
  }

  function saveScreen() {
    const overlay = overlays[hasSelection ? selOutput : output];
    if (!selecting || busy || !overlay)
      return;
    busy = true;
    const path = fileName();
    overlay.grabScreen(result => {
      if (!result.saveToFile(path))
        return root.fail();
      root.finish("fullscreen", "Screen saved", root.shortPath(path));
    });
  }

  Timer {
    id: fallback
    interval: 1500
    onTriggered: root.begin()
  }

  Timer {
    id: closeFallback
    interval: 1200
    onTriggered: root.closed()
  }

  IpcHandler {
    target: "screenshot"

    function start(): void {
      root.start();
    }
    function cancel(): void {
      root.cancel();
    }
  }
}
