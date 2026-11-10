pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string mode: ""
  property string output: ""
  readonly property bool isOpen: mode !== ""

  readonly property string cacheDir: Paths.cache + "/clip"
  readonly property var terminals: ["kitty", "foot", "alacritty", "wezterm", "ghostty", "org.wezfurlong.wezterm", "com.mitchellh.ghostty"]

  property string calcQuery: ""
  property string calcResult: ""
  property var clips: []
  property bool clipsLoading: false
  property var thumbs: ({})
  property var decoding: ({})
  property var localIcons: ({})

  function open(next) {
    output = Niri.activeOutput;
    mode = next;
    iconScan.running = true;
  }

  function iconFor(name) {
    if (!name)
      return "";
    if (name.startsWith("/"))
      return Paths.fileUrl(name);
    if (localIcons[name])
      return Paths.fileUrl(localIcons[name]);
    return Quickshell.iconPath(name, true);
  }

  function parseIcons(text) {
    const best = {};
    const rank = {};
    for (const path of text.split("\n")) {
      const match = path.match(/\/(\d+)x\d+\/apps\/([^/]+)\.(png|svg)$/) ?? path.match(/\/(scalable)\/apps\/([^/]+)\.(svg)$/);
      if (!match)
        continue;
      const size = match[1] === "scalable" ? 100 : Number(match[1]);
      if (!(match[2] in rank) || size > rank[match[2]]) {
        rank[match[2]] = size;
        best[match[2]] = path;
      }
    }
    localIcons = best;
  }

  Process {
    id: iconScan
    running: true
    command: ["sh", "-c", 'IFS=:; for d in "$HOME/.local/share" $XDG_DATA_DIRS; do [ -d "$d/icons/hicolor" ] && find -L "$d/icons/hicolor" -path "*/apps/*" \\( -name "*.png" -o -name "*.svg" \\) 2>/dev/null; done']
    stdout: StdioCollector {
      onStreamFinished: root.parseIcons(this.text)
    }
  }

  function toggle() {
    if (isOpen)
      close();
    else
      open("launcher");
  }

  function toggleClipboard() {
    if (mode === "clipboard")
      close();
    else
      open("clipboard");
  }

  function close() {
    mode = "";
    calcQuery = "";
    calcResult = "";
  }

  function scoreText(text, q) {
    if (!text)
      return 0;
    const t = text.toLowerCase();
    if (t === q)
      return 120;
    if (t.startsWith(q))
      return 100;
    if (t.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
      return 80;
    if (t.includes(q))
      return 60;
    let i = 0;
    for (const c of t) {
      if (c === q[i])
        i++;
      if (i === q.length)
        return 20;
    }
    return 0;
  }

  function apps(text) {
    const q = text.trim().toLowerCase();
    const counts = usage.counts ?? {};
    const list = [];
    for (const entry of DesktopEntries.applications.values) {
      if (entry.noDisplay)
        continue;
      const used = counts[entry.id] ?? 0;
      let score = 0;
      if (q === "") {
        score = 1;
      } else {
        score = Math.max(scoreText(entry.name, q), scoreText(entry.genericName, q) * 0.6, Math.max(0, ...(entry.keywords ?? []).map(k => scoreText(k, q))) * 0.5, scoreText(entry.id, q) * 0.5);
        if (score === 0)
          continue;
      }
      list.push({
        entry: entry,
        score: score + Math.log(used + 1) * 12
      });
    }
    list.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));
    return list.map(r => r.entry);
  }

  function launch(entry) {
    const counts = Object.assign({}, usage.counts ?? {});
    counts[entry.id] = (counts[entry.id] ?? 0) + 1;
    usage.counts = counts;
    usageFile.writeAdapter();
    close();
    entry.execute();
  }

  function isMath(text) {
    const t = text.trim();
    if (t.startsWith("="))
      return t.length > 1;
    if (!/\d/.test(t))
      return /^(sqrt|cbrt|sin|cos|tan|log|ln|abs|exp|pi)\b/i.test(t);
    if (/^[\s\d.,+\-*/^%()×÷π!]+$/.test(t))
      return /[+\-*/^%×÷!]/.test(t.replace(/^\s*-/, ""));
    if (/^(sqrt|cbrt|sin|cos|tan|log|ln|abs|exp|round|floor|ceil)\s*\(/i.test(t))
      return true;
    return /\d.*\s(to|in)\s+\S/i.test(t);
  }

  function calculate(text) {
    if (!isMath(text)) {
      calcQuery = "";
      calcResult = "";
      calcDebounce.stop();
      return;
    }
    calcQuery = text.trim().replace(/^=\s*/, "");
    calcDebounce.restart();
  }

  function copy(text) {
    Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy', "sh", text]);
  }

  function copyResult() {
    if (calcResult === "")
      return;
    copy(calcResult.replace(/−/g, "-"));
    close();
  }

  function loadClips() {
    clipsLoading = true;
    clipList.running = true;
  }

  function parseClips(text) {
    clips = text.split("\n").filter(l => l !== "").map(line => {
      const tab = line.indexOf("\t");
      const id = line.slice(0, tab);
      const preview = line.slice(tab + 1);
      const image = preview.match(/^\[\[ binary data .* (png|jpe?g|webp|bmp|gif) (\d+x\d+) \]\]$/);
      return {
        id: id,
        preview: preview,
        isImage: image !== null,
        ext: image ? image[1] : "",
        size: image ? image[2] : ""
      };
    });
    clipsLoading = false;
  }

  function thumb(clip) {
    if (!clip.isImage)
      return "";
    const path = `${cacheDir}/${clip.id}.${clip.ext}`;
    if (thumbs[clip.id])
      return thumbs[clip.id];
    if (decoding[clip.id])
      return "";
    decoding[clip.id] = true;
    const proc = decoder.createObject(root, {
      clipId: clip.id,
      path: path
    });
    proc.running = true;
    return "";
  }

  function paste(clip) {
    close();
    Quickshell.execDetached(["sh", Paths.scripts + "/clip-paste.sh", clip.id, ...terminals]);
  }

  function remove(clip) {
    clips = clips.filter(c => c.id !== clip.id);
    Quickshell.execDetached(["sh", "-c", 'cliphist list | awk -F "\t" -v id="$1" \'$1 == id\' | cliphist delete', "sh", clip.id]);
  }

  Timer {
    id: calcDebounce
    interval: 150
    onTriggered: {
      calc.command = ["qalc", "-t", "--", root.calcQuery];
      calc.running = true;
    }
  }

  Process {
    id: calc
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = this.text.split("\n").map(l => l.trim()).filter(l => l !== "");
        const result = lines[lines.length - 1] ?? "";
        const normalized = s => s.replace(/\s+/g, "").replace(/−/g, "-");
        if (result === "" || normalized(result) === normalized(root.calcQuery) || /error|warning/i.test(result))
          root.calcResult = "";
        else
          root.calcResult = result;
      }
    }
  }

  Process {
    id: clipList
    command: ["cliphist", "list"]
    stdout: StdioCollector {
      onStreamFinished: root.parseClips(this.text)
    }
    onExited: code => {
      if (code !== 0)
        root.clips = [];
    }
    onRunningChanged: {
      if (!running)
        root.clipsLoading = false;
    }
  }

  Component {
    id: decoder

    Process {
      id: proc

      property string clipId
      property string path

      command: ["sh", "-c", 'mkdir -p "$(dirname "$2")" && [ -s "$2" ] || cliphist decode "$1" > "$2"', "sh", clipId, path]
      onExited: code => {
        if (code === 0) {
          const next = Object.assign({}, root.thumbs);
          next[proc.clipId] = proc.path;
          root.thumbs = next;
        }
        proc.destroy();
      }
    }
  }

  FileView {
    id: usageFile
    path: Paths.state + "/launcher.json"
    printErrors: false

    JsonAdapter {
      id: usage
      property var counts: ({})
    }
  }

  IpcHandler {
    target: "launcher"

    function toggle(): void {
      root.toggle();
    }
    function toggleClipboard(): void {
      root.toggleClipboard();
    }
    function close(): void {
      root.close();
    }
  }
}
