pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel

Singleton {
  id: root

  readonly property bool safeOnly: settings.safeOnly
  readonly property string directory: Settings.danbooruDirectory
  readonly property string userAgent: "yurice/1.0 (quickshell danbooru widget)"
  readonly property string apiBase: "https://danbooru.donmai.us"
  readonly property int pageSize: 30
  readonly property var imageExts: ["jpg", "jpeg", "png", "webp", "gif"]

  property string query: settings.query
  property string phase: "idle"
  property string error: ""
  property var results: []
  property int page: 1
  property bool hasMore: false
  property bool loadingMore: false
  property var downloads: ({})
  property var saved: ({})
  property int requestId: 0

  property string health: "unknown"
  property bool watching: false
  property string notice: ""

  readonly property bool searching: phase === "searching"
  readonly property bool downloading: Object.keys(downloads).length > 0
  readonly property bool busy: searching || downloading
  readonly property bool down: health === "down"
  readonly property var credentials: keyFile.text().split("\n").map(s => s.trim())
  readonly property string login: credentials[0] ?? ""
  readonly property string apiKey: credentials[1] ?? ""
  readonly property bool hasApiKey: login !== "" && apiKey !== ""

  function setCredentials(name, key) {
    const content = name.trim() !== "" && key.trim() !== "" ? `${name.trim()}\n${key.trim()}` : "";
    keyWriter.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && umask 077 && printf %s "$2" > "$1"', "sh", keyFile.path, content];
    keyWriter.running = true;
  }

  function setSafeOnly(on) {
    settings.safeOnly = on;
    settingsFile.writeAdapter();
    if (phase !== "idle")
      search(query);
  }

  function showNotice(text) {
    notice = text;
    noticeTimer.restart();
  }

  function checkHealth() {
    if (!healthCheck.running)
      healthCheck.running = true;
  }

  function setHealth(next) {
    const wasDown = health !== "up";
    health = next;
    if (next === "up" && wasDown && watching && phase === "error")
      search(query);
  }

  onWatchingChanged: if (watching)
    checkHealth()

  function buildUrl(q, p) {
    const tags = (safeOnly ? q + " rating:g" : q).trim();
    return `${apiBase}/posts.json?limit=${pageSize}&page=${p}&tags=${encodeURIComponent(tags)}`;
  }

  function parse(body) {
    const list = JSON.parse(body);
    if (!Array.isArray(list))
      throw new Error("unexpected response");
    return {
      items: list.filter(p => p.file_url && imageExts.includes(p.file_ext)).map(p => {
        const variants = p.media_asset?.variants ?? [];
        const preview = variants.find(v => v.type === "720x720") ?? variants.find(v => v.type === "360x360");
        return {
          id: String(p.id),
          thumb: preview?.url ?? p.preview_file_url,
          full: p.file_url,
          resolution: `${p.image_width}x${p.image_height}`,
          ext: p.file_ext
        };
      }),
      more: list.length >= pageSize
    };
  }

  function describe(status, body) {
    try {
      const data = JSON.parse(body);
      if (data.message)
        return data.message;
    } catch (e) {}
    if (status === 0)
      return "No connection";
    if (status === 401)
      return "Wrong username or API key";
    if (status === 429)
      return "Too many requests, try again in a minute";
    if (status >= 500)
      return "Danbooru is unavailable right now";
    return `Search failed (${status})`;
  }

  function fetch(p, done) {
    const id = ++requestId;
    const proc = fetcher.createObject(root, {
      requestId: id,
      url: buildUrl(query, p),
      done: done
    });
    proc.running = true;
  }

  function clearResults() {
    requestId++;
    phase = "idle";
    results = [];
    hasMore = false;
    loadingMore = false;
    error = "";
  }

  Connections {
    target: WeebMode
    function onHidesDanbooruChanged() {
      if (WeebMode.hidesDanbooru)
        root.clearResults();
    }
  }

  function search(q) {
    if (WeebMode.hidesDanbooru)
      return;
    query = q.trim();
    settings.query = query;
    settingsFile.writeAdapter();
    page = 1;
    results = [];
    hasMore = false;
    loadingMore = false;
    error = "";
    phase = "searching";
    fetch(1, (res, err) => {
      if (!res) {
        error = err;
        phase = "error";
        return;
      }
      results = res.items;
      hasMore = res.more;
      phase = "results";
    });
  }

  function loadMore() {
    if (WeebMode.hidesDanbooru || phase !== "results" || !hasMore || loadingMore)
      return;
    loadingMore = true;
    fetch(page + 1, (res, err) => {
      loadingMore = false;
      if (!res)
        return;
      page += 1;
      const seen = new Set(results.map(r => r.id));
      results = results.concat(res.items.filter(r => !seen.has(r.id)));
      hasMore = res.more;
    });
  }

  function fileName(item) {
    return `danbooru-${item.id}.${item.ext}`;
  }

  function isSaved(item) {
    return saved[fileName(item)] === true;
  }

  function isDownloading(item) {
    return downloads[fileName(item)] === true;
  }

  function setDownloading(key, on) {
    const next = Object.assign({}, downloads);
    if (on)
      next[key] = true;
    else
      delete next[key];
    downloads = next;
  }

  function save(item) {
    const name = fileName(item);
    if (WeebMode.hidesDanbooru || downloads[name] || saved[name])
      return;
    setDownloading(name, true);
    const proc = downloader.createObject(root, {
      name: name,
      url: item.full
    });
    proc.running = true;
  }

  function rebuildSaved() {
    const next = {};
    for (let i = 0; i < folder.count; i++)
      next[folder.get(i, "fileName")] = true;
    saved = next;
  }

  Process {
    id: keyWriter
    onExited: keyFile.reload()
  }

  Process {
    id: healthCheck
    command: ["curl", "-s", "-m", "10", "-A", root.userAgent, "-o", "/dev/null", "-w", "%{http_code} %{content_type}", root.apiBase + "/posts.json?limit=1"]
    stdout: StdioCollector {
      onStreamFinished: {
        const [code, type] = text.trim().split(" ");
        const status = parseInt(code) || 0;
        const json = String(type).includes("json");
        if (status === 0)
          root.setHealth("offline");
        else if (status >= 500 || !json)
          root.setHealth("down");
        else
          root.setHealth("up");
      }
    }
  }

  Timer {
    interval: 30000
    repeat: true
    running: root.watching && root.health !== "up"
    onTriggered: root.checkHealth()
  }

  Timer {
    id: noticeTimer
    interval: 4000
    onTriggered: root.notice = ""
  }

  Component {
    id: fetcher

    Process {
      id: proc

      property int requestId
      property string url
      property var done

      command: ["curl", "-sSL", "-m", "20", "-A", root.userAgent, "-w", "\n%{http_code}"].concat(root.hasApiKey ? ["-u", `${root.login}:${root.apiKey}`] : []).concat([url])
      stdout: StdioCollector {
        id: out
      }
      onExited: code => {
        if (proc.requestId === root.requestId) {
          const text = out.text;
          const cut = text.lastIndexOf("\n");
          const status = code === 0 ? parseInt(text.slice(cut + 1)) || 0 : 0;
          const body = cut >= 0 ? text.slice(0, cut) : "";
          if (status !== 0)
            root.setHealth(status >= 500 ? "down" : "up");
          if (status !== 200) {
            proc.done(null, root.describe(status, body));
          } else {
            let res = null;
            try {
              res = root.parse(body);
            } catch (e) {
              root.setHealth("down");
              proc.done(null, "Danbooru is unavailable right now");
            }
            if (res)
              proc.done(res, "");
          }
        }
        proc.destroy();
      }
    }
  }

  Component {
    id: downloader

    Process {
      id: dl

      property string name
      property string url

      command: ["sh", "-c", 'mkdir -p "$1" && curl -fsSL --retry 2 -A "$4" -o "$1/$2.part" "$3" && mv "$1/$2.part" "$1/$2"', "sh", root.directory, name, url, root.userAgent]
      onExited: code => {
        root.setDownloading(dl.name, false);
        if (code === 0) {
          root.showNotice("Saved to " + Paths.display(root.directory));
        } else {
          root.showNotice("Couldn't save image");
          console.warn("Danbooru: download failed", dl.url);
        }
        dl.destroy();
      }
    }
  }

  onDirectoryChanged: {
    ensureDirectory.running = false;
    ensureDirectory.running = true;
  }

  Process {
    id: ensureDirectory
    running: true
    command: ["mkdir", "-p", root.directory]
    onExited: folder.folder = Paths.fileUrl(root.directory)
  }

  FolderListModel {
    id: folder
    showDirs: false
    onCountChanged: root.rebuildSaved()
    onStatusChanged: if (status === FolderListModel.Ready)
      root.rebuildSaved()
  }

  FileView {
    id: keyFile
    path: Paths.config + "/danbooru.key"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  FileView {
    id: settingsFile
    path: Paths.state + "/danbooru.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()

    JsonAdapter {
      id: settings
      property string query: ""
      property bool safeOnly: true
    }
  }
}
