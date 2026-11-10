pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import qs.components

Singleton {
  id: root

  property alias query: feed.query
  property alias phase: feed.phase
  property alias error: feed.error
  property alias results: feed.results
  property alias hasMore: feed.hasMore
  property alias loadingMore: feed.loadingMore
  property alias downloads: feed.downloads
  readonly property alias searching: feed.searching
  readonly property bool busy: feed.searching || feed.downloading
  readonly property string apiKey: keyFile.lines[0] ?? ""
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
    keyFile.write(key.trim());
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
        feed.reset();
    }
    function onHidesAdultFiltersChanged() {
      if (WeebMode.hidesAdultFilters)
        feed.reset();
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

  function parse(body) {
    const data = JSON.parse(body);
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

  function search(q) {
    feed.search(q);
  }

  function loadMore() {
    feed.loadMore();
  }

  function pathFor(item) {
    return `${Wallpapers.directory}/wallhaven-${item.id}.${item.ext}`;
  }

  function download(item) {
    const path = pathFor(item);
    if (Wallpapers.allWallpapers.includes(path))
      apply(item, path);
    else
      feed.download(item.id, item.full, path, item);
  }

  function apply(item, path) {
    if (item.purity === "sfw" && item.category !== "anime")
      Wallpapers.setSafe(path, true);
    Wallpapers.set(path);
  }

  SearchFeed {
    id: feed
    urlFor: (q, p) => root.buildUrl(q, p)
    parser: body => root.parse(body)
    onDownloaded: (key, path, item) => root.apply(item, path)
    onDownloadFailed: (key, url) => console.warn("WallSearch: download failed", url)
  }

  KeyFile {
    id: keyFile
    path: Paths.config + "/wallhaven.key"
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
