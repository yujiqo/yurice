pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string kdlPath: Settings.home + "/.config/yurice/custom/niri/outputs.kdl"
  readonly property int confirmSeconds: 10

  property bool editing: false
  property string selected: ""
  property var outputs: []
  property var draft: ({})
  property var snapshot: null
  property int countdown: 0
  property bool busy: false
  property string error: ""
  property bool resume: false
  property var confirmScreens: []
  property int views: 0
  readonly property bool confirming: snapshot !== null
  readonly property bool dirty: outputs.some(o => !same(draft[o.name], stateOf(o)))
  readonly property int enabledCount: outputs.filter(o => draft[o.name]?.enabled ?? o.enabled).length

  function open() {
    editing = true;
    refresh();
  }

  function close() {
    editing = false;
    resume = false;
  }

  function detach() {
    editing = false;
  }

  function scheduleResume() {
    if (resume)
      resumeTimer.restart();
  }

  function refresh() {
    if (!reader.running)
      reader.running = true;
  }

  function normalizeTransform(value) {
    const t = String(value ?? "Normal").toLowerCase().replace(/^_/, "");
    return t.startsWith("flipped") && t !== "flipped" ? "flipped-" + t.slice(7) : t;
  }

  function stateOf(output) {
    return {
      enabled: output.enabled,
      width: output.mode.width,
      height: output.mode.height,
      refresh: output.mode.refresh,
      scale: output.scale,
      transform: output.transform,
      x: output.x,
      y: output.y
    };
  }

  function same(a, b) {
    return JSON.stringify(a) === JSON.stringify(b);
  }

  function modeText(state) {
    return `${state.width}x${state.height}@${(state.refresh / 1000).toFixed(3)}`;
  }

  function parse(text) {
    let data = {};
    try {
      data = JSON.parse(text);
    } catch (e) {
      error = "Couldn't read outputs from niri";
      return;
    }
    const stored = Settings.values.outputs ?? {};
    const list = Object.values(data).map(o => {
      const modes = (o.modes ?? []).map(m => ({
            width: m.width,
            height: m.height,
            refresh: m.refresh_rate,
            preferred: m.is_preferred
          }));
      const enabled = o.current_mode !== null && o.current_mode !== undefined && !!o.logical;
      let mode = enabled ? modes[o.current_mode] : null;
      if (!mode) {
        const saved = stored[o.name]?.mode ?? "";
        const match = saved.match(/^(\d+)x(\d+)(?:@([\d.]+))?$/);
        mode = match ? modes.filter(m => m.width === +match[1] && m.height === +match[2]).sort((a, b) => Math.abs(a.refresh - (+match[3] || 0) * 1000) - Math.abs(b.refresh - (+match[3] || 0) * 1000))[0] : null;
      }
      mode = mode ?? modes.find(m => m.preferred) ?? modes[0] ?? {
        width: 0,
        height: 0,
        refresh: 0
      };
      return {
        name: o.name,
        title: [o.make, o.model].filter(s => s && s !== "Unknown").join(" ") || o.name,
        modes: modes,
        enabled: enabled,
        mode: {
          width: mode.width,
          height: mode.height,
          refresh: mode.refresh
        },
        scale: o.logical?.scale ?? stored[o.name]?.scale ?? 1,
        transform: normalizeTransform(o.logical?.transform ?? stored[o.name]?.transform),
        x: o.logical?.x ?? stored[o.name]?.position?.x ?? 0,
        y: o.logical?.y ?? stored[o.name]?.position?.y ?? 0
      };
    }).sort((a, b) => a.x - b.x || a.name.localeCompare(b.name));
    const previous = outputs;
    outputs = list;
    if (!confirming) {
      const next = {};
      list.forEach(o => {
        const old = previous.find(p => p.name === o.name);
        const edited = old && draft[o.name] && !same(draft[o.name], stateOf(old));
        next[o.name] = edited ? draft[o.name] : stateOf(o);
      });
      draft = next;
    }
    if (!list.some(o => o.name === selected))
      selected = list[0]?.name ?? "";
    error = "";
  }

  function update(name, changes) {
    if (confirming || !draft[name])
      return;
    const next = Object.assign({}, draft);
    next[name] = Object.assign({}, draft[name], changes);
    draft = next;
  }

  function setResolution(name, width, height) {
    const output = outputs.find(o => o.name === name);
    const current = draft[name];
    if (!output || !current)
      return;
    const rates = output.modes.filter(m => m.width === width && m.height === height).map(m => m.refresh);
    const keep = rates.find(r => r === current.refresh);
    update(name, {
      width: width,
      height: height,
      refresh: keep ?? Math.max(...rates)
    });
  }

  function reset() {
    if (confirming)
      return;
    const next = {};
    outputs.forEach(o => next[o.name] = stateOf(o));
    draft = next;
  }

  function commandsFor(states) {
    const lines = [];
    const names = Object.keys(states);
    names.filter(n => states[n].enabled).forEach(n => {
      const s = states[n];
      const q = `'${n}'`;
      lines.push(`niri msg output ${q} on`);
      lines.push(`niri msg output ${q} mode ${modeText(s)}`);
      lines.push(`niri msg output ${q} scale ${s.scale}`);
      lines.push(`niri msg output ${q} transform ${s.transform}`);
      lines.push(`niri msg output ${q} position set -- ${Math.round(s.x)} ${Math.round(s.y)}`);
    });
    names.filter(n => !states[n].enabled).forEach(n => lines.push(`niri msg output '${n}' off`));
    return lines.join("\n");
  }

  function run(states) {
    busy = true;
    runner.command = ["sh", "-c", commandsFor(states)];
    runner.running = true;
  }

  function apply() {
    if (confirming || busy || !dirty || enabledCount === 0)
      return;
    const before = {};
    outputs.forEach(o => before[o.name] = stateOf(o));
    const changed = outputs.filter(o => !same(draft[o.name], before[o.name]) && draft[o.name].enabled).map(o => o.name);
    const fallback = Niri.focusedOutput || outputs.find(o => draft[o.name]?.enabled)?.name || "";
    confirmScreens = changed.length > 0 ? changed : [fallback];
    snapshot = before;
    resume = editing;
    if (Panels.name === "user")
      Panels.close();
    run(draft);
    countdown = confirmSeconds;
    confirmTimer.restart();
  }

  function revert() {
    if (!confirming)
      return;
    confirmTimer.stop();
    const previous = snapshot;
    snapshot = null;
    countdown = 0;
    draft = previous;
    run(previous);
    scheduleResume();
  }

  function keep() {
    if (!confirming)
      return;
    confirmTimer.stop();
    snapshot = null;
    countdown = 0;
    scheduleResume();
    const stored = Object.assign({}, Settings.values.outputs ?? {});
    outputs.forEach(o => {
      const s = draft[o.name];
      if (!s)
        return;
      stored[o.name] = {
        off: !s.enabled,
        mode: modeText(s),
        scale: s.scale,
        transform: s.transform,
        position: {
          x: Math.round(o.enabled ? o.x : s.x),
          y: Math.round(o.enabled ? o.y : s.y)
        }
      };
    });
    Settings.set("outputs", stored);
    writeKdl(stored);
  }

  function writeKdl(stored) {
    const blocks = Object.keys(stored).sort().map(name => {
      const o = stored[name];
      const lines = [`output "${name}" {`];
      if (o.off)
        lines.push("  off");
      if (o.mode)
        lines.push(`  mode "${o.mode}"`);
      lines.push(`  scale ${o.scale ?? 1}`);
      lines.push(`  transform "${o.transform ?? "normal"}"`);
      if (o.position)
        lines.push(`  position x=${o.position.x} y=${o.position.y}`);
      lines.push("", "  hot-corners {", "    off", "  }", "}");
      return lines.join("\n");
    });
    kdl.setText(blocks.join("\n\n") + "\n");
  }

  Timer {
    id: confirmTimer
    interval: 1000
    repeat: true
    onTriggered: {
      root.countdown--;
      if (root.countdown <= 0)
        root.revert();
    }
  }

  Process {
    id: reader
    command: ["niri", "msg", "-j", "outputs"]
    stdout: StdioCollector {
      onStreamFinished: root.parse(text)
    }
  }

  Process {
    id: runner
    stderr: StdioCollector {
      id: runnerErrors
    }
    onExited: code => {
      root.busy = false;
      if (code !== 0) {
        root.error = "niri rejected the change";
        console.warn("Displays:", runnerErrors.text.trim());
      }
      settle.restart();
    }
  }

  Timer {
    id: resumeTimer
    interval: 900
    onTriggered: {
      root.resume = false;
      if (root.views > 0)
        return;
      root.editing = true;
      root.refresh();
      Panels.open("user");
    }
  }

  Timer {
    id: settle
    interval: 300
    onTriggered: root.refresh()
  }

  Connections {
    target: Quickshell
    function onScreensChanged() {
      root.refresh();
    }
  }

  FileView {
    id: kdl
    path: root.kdlPath
    blockWrites: true
    printErrors: false
  }

  Component.onCompleted: refresh()
}
