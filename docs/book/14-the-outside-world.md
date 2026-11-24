# 14. The outside world

Three islands talk to websites: weather, wallpapers (through wallhaven) and danbooru. The network is the least reliable thing the shell deals with. Requests are slow, fail, come back out of order, or come back after you've already asked for something else. This chapter is mostly about handling that, and about the two services that need API keys.

Chapter 7 listed four ways a service learns things. The web adds a fifth, HTTP, done two ways here: QML's built-in `XMLHttpRequest` for small JSON requests, and `curl` through `Process` for everything that needs headers, credentials or files on disk.

## Weather

[`services/Weather.qml`](../../config/quickshell/services/Weather.qml) needs no key. It uses [open-meteo](https://open-meteo.com) for forecasts and, unless you've set a location, [ipinfo.io](https://ipinfo.io) to guess where you are from your IP address.

Requests go through a small helper around `XMLHttpRequest`, which QML provides the same way a browser does:

```qml
  function request(url, done) {
    const xhr = new XMLHttpRequest();
    xhr.onreadystatechange = () => {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return;
      if (xhr.status !== 200) {
        done(null);
        return;
      }
      try {
        done(JSON.parse(xhr.responseText));
      } catch (e) {
        done(null);
      }
    };
    xhr.open("GET", url);
    xhr.send();
  }
```

[`services/Weather.qml:95-112`](../../config/quickshell/services/Weather.qml#L95-L112)

Any failure, a bad status or broken JSON, becomes `done(null)`. The caller only has to handle "got data" and "didn't".

### Answers that arrive too late

Say you change the weather location twice in quick succession. Two requests are now in flight, and nothing guarantees the first one finishes first. If it finishes second, the panel shows the wrong city.

The fix is a counter:

```qml
  function refresh() {
    if (loading)
      return;
    loading = true;
    const token = ++generation;
    if (isNaN(latitude) || isNaN(longitude)) {
      request("https://ipinfo.io/json", data => {
        if (token !== generation)
          return;
        ...
        fetchForecast(token);
      });
    } else {
      fetchForecast(token);
    }
  }
```

[`services/Weather.qml:150-172`](../../config/quickshell/services/Weather.qml#L150-L172)

Every request remembers the `generation` it started with. When the answer arrives, it checks that it's still the latest, and quietly drops itself if not. The same check is done when the forecast arrives, and city search uses its own `searchGeneration` the same way. You'll see this pattern again in every service in this chapter, under different names.

### Refreshing

Two timers keep it fresh:

```qml
  Timer {
    interval: 15 * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: retry
    interval: 60 * 1000
    onTriggered: root.refresh()
  }
```

[`services/Weather.qml:249-261`](../../config/quickshell/services/Weather.qml#L249-L261)

The forecast is fetched at startup and every 15 minutes. A failure starts the retry timer, so a laptop that wakes up offline gets the weather a minute after the network comes back, not 15 minutes later.

When new data arrives while the old data is on screen, the service fades `fade` to 0, swaps the values, and fades back in. The island and panel bind their text's opacity to `Weather.fade`, so numbers never change mid-glance. The island itself springs into existence only once `Weather.ready` is true, so you never see a "0°" placeholder at startup.

Weather codes from open-meteo are WMO numbers. `describe(code, isDay)` turns them into text and an icon, with night versions for clear and partly cloudy skies.

## SearchFeed: the shared part

Wallhaven and danbooru both search an image site page by page, show thumbnails in a grid, load more as you scroll, and download the image you pick. Commit "share some logic between wallhaven and danbooru search" moved everything they have in common into [`components/SearchFeed.qml`](../../config/quickshell/components/SearchFeed.qml). Each service then only supplies what's specific to its site:

```qml
  required property var urlFor
  required property var parser
  property var describe: status => status === 0 ? "No connection" : status === 429 ? "Too many requests, try again in a minute" : `Search failed (${status})`
  property string parseError: "Unexpected response"
  property string userAgent: ""
  property var curlArgs: []
  property var prepare: null
```

[`components/SearchFeed.qml:10-16`](../../config/quickshell/components/SearchFeed.qml#L10-L16)

These are functions passed in as properties. `urlFor(query, page)` builds a URL, `parser(body)` turns a response into `{ items, more }`, and `describe` turns an HTTP status into a message for the panel. `prepare` is an optional step before the first page, which danbooru uses.

In return, the feed exposes a small state machine: `phase` is `idle`, `searching`, `results` or `error`, plus `results`, `hasMore`, `loadingMore` and `downloads`. The panels only read those.

### One process per request

Each request is a `curl` run. Since several can be in flight, the feed doesn't use a single `Process`. It keeps a `Component` and creates a new process for each request:

```qml
  property Component fetcher: Component {
    Process {
      id: proc

      property int requestId
      property string url

      command: ["curl", "-sSL", "-m", "20", "-w", "\n%{http_code}"].concat(root.userAgent !== "" ? ["-A", root.userAgent] : []).concat(root.curlArgs).concat([url])
      stdout: StdioCollector {
        id: out
      }
      onExited: code => {
        const text = out.text;
        const cut = text.lastIndexOf("\n");
        const status = code === 0 ? parseInt(text.slice(cut + 1)) || 0 : 0;
        root.receive(proc.requestId, status, cut >= 0 ? text.slice(0, cut) : "");
        proc.destroy();
      }
    }
  }
```

[`components/SearchFeed.qml:174-193`](../../config/quickshell/components/SearchFeed.qml#L174-L193)

`createObject(root, { requestId, url })` makes one, it runs, and it destroys itself when done. `-w "\n%{http_code}"` makes curl print the status code on its own line after the body, which is how the feed gets both from one process: everything before the last newline is the body, and the last line is the status. A curl failure (no network, timeout) is reported as status 0, which `describe` turns into "No connection".

`requestId` is the generation counter again. `receive` drops any answer whose id isn't the one it's waiting for, so typing a new query while the old one loads can't mix the two result lists.

Two more details. When a site returns a page where everything was filtered out, the feed skips ahead up to 5 empty pages before giving up, so you don't get a blank grid with "load more" under it. And when loading more, it drops results whose id it has already shown, since sites that sort randomly can return the same image twice.

Downloads go through [`scripts/download.sh`](../../config/quickshell/scripts/download.sh), which writes to `name.part` and renames it only when curl succeeds. A half-downloaded file never shows up in your wallpaper folder.

## Wallhaven

[`services/WallSearch.qml`](../../config/quickshell/services/WallSearch.qml) plugs wallhaven into the feed:

```qml
  SearchFeed {
    id: feed
    urlFor: (q, p) => root.buildUrl(q, p)
    parser: body => root.parse(body)
    onDownloaded: (key, path, item) => root.apply(item, path)
    onDownloadFailed: (key, url) => console.warn("WallSearch: download failed", url)
  }
```

[`services/WallSearch.qml:119-125`](../../config/quickshell/services/WallSearch.qml#L119-L125)

Wallhaven's API describes filters as bit strings. `categories` is three bits for general, anime and people, and `purity` is three bits for SFW, sketchy and NSFW. `"110"` means general and anime, but not people. The filter chips in the panel flip single bits, and `toggleBit` refuses to turn off the last one, since a search with no categories returns nothing.

The API key is optional and lives in `~/.config/yurice/wallhaven.key`, read with `KeyFile` (chapter 7). Wallhaven only returns sketchy and NSFW results to logged-in users, so without a key purity is forced to `"100"`:

```qml
  readonly property string purity: hasApiKey && !WeebMode.hidesAdultFilters ? filters.purity : "100"
```

[`services/WallSearch.qml:30`](../../config/quickshell/services/WallSearch.qml#L30)

The `WeebMode` part is chapter 16. The search also passes `atleast` with your screen resolution by default, so you don't download wallpapers smaller than your monitor.

When a download finishes, it becomes your wallpaper right away. If wallhaven marked it SFW and it isn't in the anime category, it's also marked safe for the second mode:

```qml
  function apply(item, path) {
    if (item.purity === "sfw" && item.category !== "anime")
      Wallpapers.setSafe(path, true);
    Wallpapers.set(path);
  }
```

[`services/WallSearch.qml:113-117`](../../config/quickshell/services/WallSearch.qml#L113-L117)

## Danbooru

[`services/Danbooru.qml`](../../config/quickshell/services/Danbooru.qml) is the largest service in this part, because danbooru has rules the others don't.

### The key and its permissions

Danbooru works without an account, but with tight limits: two tags per search and 1000 pages of results. With an account and an API key, the limits follow your account level. The key file `~/.config/yurice/danbooru.key` has your username on the first line and the key on the second.

When you create the key on danbooru, it asks which API endpoints it may use. yurice needs exactly three, and each matches one request in this service:

| Permission      | Used for                                                   |
| --------------- | ---------------------------------------------------------- |
| `posts:index`   | the search itself (`/posts.json`)                          |
| `counts:posts`  | counting results for random sorting (`/counts/posts.json`) |
| `users:profile` | reading your account level and tag limit (`/profile.json`) |

The credentials are passed to curl with `-u login:key`, and the profile is fetched again whenever either line of the key file changes. `limitFor` turns your level into a tag limit and a page limit, and the search field shows how many tags you have left.

A wrong key comes back as status 401, which `describe` turns into "Wrong username or API key". Danbooru's own error messages are used when the response has one.

### Random that doesn't repeat

Danbooru's default sorting here is random, and "random" is harder than it sounds. Asking the API for random posts gives you a different handful each time, but scrolling would then repeat images. So yurice randomizes pages instead:

```qml
  function planPages(total, seen) {
    const all = Array.from({
      length: total
    }, (_, i) => i + 1);
    return shuffle(all.filter(p => !seen[p])).concat(shuffle(all.filter(p => seen[p])));
  }
```

[`services/Danbooru.qml:119-124`](../../config/quickshell/services/Danbooru.qml#L119-L124)

Before the first page, the feed's `prepare` step asks `/counts/posts.json` how many posts match, works out how many pages that is (capped by your page limit), and shuffles the page numbers. Pages you've already seen for this query go to the back of the list, so searching the same tags again shows you new images first. `urlFor` then maps "page 3 of the feed" to whatever real page the plan says.

### Safe by default

`safeOnly` adds `rating:g` (general) to every search. It's on by default, and the second mode can force it on regardless of the setting. The same tag is also counted when planning pages, so the counts match what you'll actually see.

### Is danbooru up?

When danbooru is struggling, it can answer with something that isn't JSON at all. A parse failure or a status of 500 or more marks the service as `down`. While the panel is open and the site is down, a health check runs every 30 seconds, and when the site comes back, the failed search is retried by itself.

### Thumbnails

Thumbnails are fetched by one `curl --parallel` run per page of results, up to 8 at a time, into `~/.cache/yurice/danbooru`. That folder is deleted every time the shell starts, so it never grows without bound. Saved images go to your danbooru folder (`~/Pictures/Danbooru` by default), and a `FolderListModel` watching that folder is how the panel knows which results you've already saved.

These services all live on the bar's left side next to one that's about you instead: the user island.
