pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import qs.components

Singleton {
  id: root

  readonly property bool safeOnly: settings.safeOnly || WeebMode.hidesAdultFilters
  readonly property string thumbDir: Paths.cache + "/danbooru"
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
  property var thumbs: ({})
  property var thumbsPending: ({})

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
  readonly property string sorting: settings.sorting === "newest" ? "newest" : "random"
  property int tagLimit: 2
  property int pageLimit: 1000
  property var plan: []
  property int planToken: 0
  property var seenPages: ({})
  property bool searchSafe: true

  function setCredentials(name, key) {
    keyFile.write(name.trim() !== "" && key.trim() !== "" ? `${name.trim()}\n${key.trim()}` : "");
  }

  function setSafeOnly(on) {
    if (settings.safeOnly === on)
      return;
    settings.safeOnly = on;
    settingsFile.writeAdapter();
  }

  function setSorting(next) {
    if (settings.sorting === next)
      return;
    settings.sorting = next;
    settingsFile.writeAdapter();
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

  function tagsFor(q) {
    return (searchSafe || WeebMode.hidesAdultFilters ? q + " rating:g" : q).trim();
  }

  function buildUrl(q, p) {
    return `${apiBase}/posts.json?limit=${pageSize}&page=${p}&tags=${encodeURIComponent(tagsFor(q))}`;
  }

  function seenKey(q) {
    return (searchSafe ? "g:" : "") + q.trim();
  }

  function urlFor(q, p) {
    const real = plan[p - 1] ?? p;
    if (plan.length > 0) {
      const key = seenKey(q);
      seenPages[key] = Object.assign(seenPages[key] ?? {}, {
        [real]: true
      });
    }
    return buildUrl(q, real);
  }

  function shuffle(list) {
    for (let i = list.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [list[i], list[j]] = [list[j], list[i]];
    }
    return list;
  }

  function planPages(total, seen) {
    const all = Array.from({
      length: total
    }, (_, i) => i + 1);
    return shuffle(all.filter(p => !seen[p])).concat(shuffle(all.filter(p => seen[p])));
  }

  function prepare(q, done) {
    const token = ++planToken;
    searchSafe = safeOnly;
    plan = [];
    if (sorting !== "random") {
      done();
      return;
    }
    countFetcher.createObject(root, {
      token: token,
      query: q,
      done: done
    }).running = true;
  }

  function planned(token, q, count, done) {
    if (token !== planToken)
      return;
    if (count > 0) {
      plan = planPages(Math.min(Math.ceil(count / pageSize), pageLimit), seenPages[seenKey(q)] ?? {});
      feed.pageCount = plan.length;
    }
    done();
  }

  function tagsLeft(text) {
    return tagLimit - text.split(/\s+/).filter(t => t !== "").length;
  }

  function limitFor(profile) {
    const level = profile?.level ?? 0;
    const tier = level >= 31 ? 2 : level >= 30 ? 1 : 0;
    return {
      tags: profile?.tag_query_limit > 0 ? profile.tag_query_limit : [2, 6, 12][tier],
      pages: [1000, 2000, 5000][tier]
    };
  }

  function parse(body) {
    const list = JSON.parse(body);
    if (!Array.isArray(list))
      throw new Error("unexpected response");
    return {
      items: list.filter(p => p.file_url && imageExts.includes(p.file_ext)).map(p => {
        const variants = p.media_asset?.variants ?? [];
        const preview = variants.find(v => v.type === "360x360") ?? variants.find(v => v.type === "180x180");
        const thumb = preview?.url ?? p.preview_file_url;
        return {
          id: String(p.id),
          thumb: thumb,
          thumbFile: `${p.id}.${String(thumb).split(".").pop()}`,
          ratio: p.image_height > 0 ? p.image_width / p.image_height : 0,
          full: p.file_url,
          resolution: `${p.image_width}x${p.image_height}`,
          ext: p.file_ext
        };
      }),
      more: plan.length > 0 || list.length >= pageSize
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

  function thumbFor(item) {
    return thumbs[item.thumbFile] ? Paths.fileUrl(`${thumbDir}/${item.thumbFile}`) : "";
  }

  function fetchThumbs() {
    const missing = results.filter(item => item.thumb && !thumbs[item.thumbFile] && !thumbsPending[item.thumbFile]);
    if (missing.length === 0)
      return;
    const pending = Object.assign({}, thumbsPending);
    const args = [];
    for (const item of missing) {
      pending[item.thumbFile] = true;
      args.push("-o", `${thumbDir}/${item.thumbFile}`, item.thumb);
    }
    thumbsPending = pending;
    thumbFetcher.createObject(root, {
      files: missing.map(item => item.thumbFile),
      args: args
    }).running = true;
  }

  function thumbFetched(line) {
    const cut = line.indexOf(" ");
    if (line.slice(0, cut) !== "200")
      return;
    const next = Object.assign({}, thumbs);
    next[Paths.baseName(line.slice(cut + 1))] = true;
    thumbs = next;
  }

  function thumbsSettled(files) {
    const pending = Object.assign({}, thumbsPending);
    for (const file of files)
      delete pending[file];
    thumbsPending = pending;
  }

  onResultsChanged: fetchThumbs()

  Component {
    id: thumbFetcher

    Process {
      id: fetcher

      property var files: []
      property var args: []

      command: ["curl", "-sS", "--parallel", "--parallel-max", "8", "--create-dirs", "-m", "20", "-A", root.userAgent, "-w", "%{http_code} %{filename_effective}\n"].concat(args)
      stdout: SplitParser {
        onRead: line => root.thumbFetched(line)
      }
      onExited: {
        root.thumbsSettled(fetcher.files);
        fetcher.destroy();
      }
    }
  }

  Process {
    running: true
    command: ["rm", "-rf", root.thumbDir]
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
    urlFor: (q, p) => root.urlFor(q, p)
    prepare: (q, done) => root.prepare(q, done)
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

  onLoginChanged: fetchProfile()
  onApiKeyChanged: fetchProfile()

  function applyLimits(profile) {
    const limits = limitFor(profile);
    tagLimit = limits.tags;
    pageLimit = limits.pages;
  }

  function fetchProfile() {
    profileFetch.running = false;
    if (!hasApiKey) {
      applyLimits(null);
      return;
    }
    profileFetch.running = true;
  }

  Component {
    id: countFetcher

    Process {
      id: counter

      property int token
      property string query
      property var done

      command: ["curl", "-sf", "-m", "10", "-A", root.userAgent].concat(feed.curlArgs).concat([`${root.apiBase}/counts/posts.json?tags=${encodeURIComponent(root.tagsFor(query))}`])
      stdout: StdioCollector {
        id: counted
      }
      onExited: {
        let count = 0;
        try {
          count = JSON.parse(counted.text).counts?.posts ?? 0;
        } catch (e) {}
        root.planned(counter.token, counter.query, count, counter.done);
        counter.destroy();
      }
    }
  }

  Process {
    id: profileFetch
    command: ["curl", "-sf", "-m", "10", "-A", root.userAgent, "-u", `${root.login}:${root.apiKey}`, root.apiBase + "/profile.json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.applyLimits(JSON.parse(text));
        } catch (e) {
          root.applyLimits(null);
        }
      }
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
      property string sorting: "random"
    }
  }
}
