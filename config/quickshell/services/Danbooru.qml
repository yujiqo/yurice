pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import qs.components

Singleton {
  id: root

  readonly property bool safeOnly: settings.safeOnly
  readonly property string directory: Settings.danbooruDirectory
  readonly property string userAgent: "yurice/1.0 (quickshell danbooru widget)"
  readonly property string apiBase: "https://danbooru.donmai.us"
  readonly property int pageSize: 30
  readonly property var imageExts: ["jpg", "jpeg", "png", "webp", "gif"]

  property alias query: feed.query
  property alias phase: feed.phase
  property alias error: feed.error
  property alias results: feed.results
  property alias hasMore: feed.hasMore
  property alias loadingMore: feed.loadingMore
  property alias downloads: feed.downloads
  property var saved: ({})

  property string health: "unknown"
  property bool watching: false
  property string notice: ""

  readonly property alias searching: feed.searching
  readonly property alias downloading: feed.downloading
  readonly property bool busy: searching || downloading
  readonly property bool down: health === "down"
  readonly property string login: keyFile.lines[0] ?? ""
  readonly property string apiKey: keyFile.lines[1] ?? ""
  readonly property bool hasApiKey: login !== "" && apiKey !== ""

  function setCredentials(name, key) {
    keyFile.write(name.trim() !== "" && key.trim() !== "" ? `${name.trim()}\n${key.trim()}` : "");
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

  Connections {
    target: WeebMode
    function onHidesDanbooruChanged() {
      if (WeebMode.hidesDanbooru)
        feed.reset();
    }
  }

  function search(q) {
    if (WeebMode.hidesDanbooru)
      return;
    feed.search(q);
    if (settings.query !== feed.query) {
      settings.query = feed.query;
      settingsFile.writeAdapter();
    }
  }

  function loadMore() {
    if (!WeebMode.hidesDanbooru)
      feed.loadMore();
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

  function save(item) {
    const name = fileName(item);
    if (WeebMode.hidesDanbooru || saved[name])
      return;
    feed.download(name, item.full, `${directory}/${name}`);
  }

  function rebuildSaved() {
    const next = {};
    for (let i = 0; i < folder.count; i++)
      next[folder.get(i, "fileName")] = true;
    saved = next;
  }

  SearchFeed {
    id: feed
    query: settings.query
    userAgent: root.userAgent
    curlArgs: root.hasApiKey ? ["-u", `${root.login}:${root.apiKey}`] : []
    parseError: "Danbooru is unavailable right now"
    urlFor: (q, p) => root.buildUrl(q, p)
    parser: body => root.parse(body)
    describe: (status, body) => root.describe(status, body)
    onResponded: status => root.setHealth(status >= 500 ? "down" : "up")
    onParseFailed: root.setHealth("down")
    onDownloaded: () => root.showNotice("Saved to " + Paths.display(root.directory))
    onDownloadFailed: (key, url) => {
      root.showNotice("Couldn't save image");
      console.warn("Danbooru: download failed", url);
    }
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

  KeyFile {
    id: keyFile
    path: Paths.config + "/danbooru.key"
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
