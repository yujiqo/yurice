pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string query: ""
  property string phase: "idle"
  property string error: ""
  property var results: []
  property int page: 1
  property bool hasMore: false
  property bool loadingMore: false
  property var downloads: ({})
  property var applied: ({})
  property int requestId: 0

  readonly property bool searching: phase === "searching"
  readonly property bool busy: searching || Object.keys(downloads).length > 0
  readonly property string apiKey: keyFile.text().trim()
  readonly property bool hasApiKey: apiKey !== ""
  readonly property string resolution: Wallpapers.screenResolution

  readonly property string categories: {
    if (!WeebMode.hidesAnimeFilter)
      return filters.categories;
    const bits = filters.categories[0] + "0" + filters.categories[2];
    return bits === "000" ? "100" : bits;
  }
  readonly property string purity: hasApiKey && !WeebMode.hidesAdultFilters ? filters.purity : "100"
  readonly property string sorting: filters.sorting
  readonly property bool atleast: filters.atleast

  function setApiKey(key) {
    keyWriter.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && umask 077 && printf %s "$2" > "$1"', "sh", keyFile.path, key.trim()];
    keyWriter.running = true;
  }

  Process {
    id: keyWriter
    onExited: keyFile.reload()
  }

  function setFilter(name, value) {
    filters[name] = value;
    filterFile.writeAdapter();
  }

  function toggleBit(name, index) {
    const hidesAnime = name === "categories" && WeebMode.hidesAnimeFilter;
    if (name === "purity" && WeebMode.hidesAdultFilters || hidesAnime && index === 1)
      return;
    const bits = filters[name].split("");
    bits[index] = bits[index] === "1" ? "0" : "1";
    if (!bits.some((bit, i) => bit === "1" && !(hidesAnime && i === 1)))
      return;
    setFilter(name, bits.join(""));
  }

  Connections {
    target: WeebMode
    function onHidesAnimeFilterChanged() {
      if (WeebMode.hidesAnimeFilter)
        root.reset();
    }
    function onHidesAdultFiltersChanged() {
      if (WeebMode.hidesAdultFilters)
        root.reset();
    }
  }

  function buildUrl(q, p) {
    let url = "https://wallhaven.cc/api/v1/search" + `?q=${encodeURIComponent(q)}` + `&categories=${categories}` + `&purity=${purity}` + `&sorting=${sorting}` + `&page=${p}`;
    if (sorting === "toplist")
      url += "&topRange=1y";
    if (atleast)
      url += `&atleast=${resolution}`;
    if (hasApiKey)
      url += `&apikey=${apiKey}`;
    return url;
  }

  function parse(data) {
    return {
      items: (data.data ?? []).map(w => ({
            id: w.id,
            thumb: w.thumbs.large,
            full: w.path,
            resolution: w.resolution,
            ext: w.path.split(".").pop(),
            purity: w.purity,
            category: w.category
          })),
      more: (data.meta?.current_page ?? 1) < (data.meta?.last_page ?? 1)
    };
  }

  function fetch(p, done) {
    const id = ++requestId;
    const xhr = new XMLHttpRequest();
    xhr.onreadystatechange = () => {
      if (xhr.readyState !== XMLHttpRequest.DONE || id !== requestId)
        return;
      if (xhr.status === 429) {
        done(null, "Too many requests, try again in a minute");
        return;
      }
      if (xhr.status !== 200) {
        done(null, xhr.status === 0 ? "No connection" : `Search failed (${xhr.status})`);
        return;
      }
      try {
        done(parse(JSON.parse(xhr.responseText)), "");
      } catch (e) {
        done(null, "Unexpected response");
      }
    };
    xhr.open("GET", buildUrl(query, p));
    xhr.send();
  }

  function search(q) {
    query = q.trim();
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
    if (phase !== "results" || !hasMore || loadingMore)
      return;
    loadingMore = true;
    fetch(page + 1, (res, err) => {
      loadingMore = false;
      if (!res)
        return;
      page += 1;
      results = results.concat(res.items);
      hasMore = res.more;
    });
  }

  function reset() {
    requestId++;
    phase = "idle";
    results = [];
    error = "";
  }

  function pathFor(item) {
    return `${Wallpapers.directory}/wallhaven-${item.id}.${item.ext}`;
  }

  function setDownloading(id, on) {
    const next = Object.assign({}, downloads);
    if (on)
      next[id] = true;
    else
      delete next[id];
    downloads = next;
  }

  function download(item) {
    if (downloads[item.id])
      return;
    const path = pathFor(item);
    if (Wallpapers.allWallpapers.includes(path)) {
      finish(item, path);
      return;
    }
    setDownloading(item.id, true);
    const proc = downloader.createObject(root, {
      item: item,
      path: path
    });
    proc.running = true;
  }

  function finish(item, path) {
    const next = Object.assign({}, applied);
    next[item.id] = true;
    applied = next;
    if (item.purity === "sfw" && item.category !== "anime")
      Wallpapers.setSafe(path, true);
    Wallpapers.set(path);
  }

  Component {
    id: downloader

    Process {
      id: proc

      property var item
      property string path

      command: ["sh", "-c", 'mkdir -p "$(dirname "$2")" && curl -fsSL --retry 2 -o "$2.part" "$1" && mv "$2.part" "$2"', "sh", item.full, path]
      onExited: code => {
        root.setDownloading(proc.item.id, false);
        if (code === 0)
          root.finish(proc.item, proc.path);
        else
          console.warn("WallSearch: download failed", proc.item.full);
        proc.destroy();
      }
    }
  }

  FileView {
    id: keyFile
    path: Paths.config + "/wallhaven.key"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  FileView {
    id: filterFile
    path: Paths.state + "/wallsearch.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()

    JsonAdapter {
      id: filters
      property string categories: "111"
      property string purity: "100"
      property string sorting: "relevance"
      property bool atleast: true
    }
  }
}
