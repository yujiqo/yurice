pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

Scope {
  id: root

  required property var urlFor
  required property var parser
  property var describe: status => status === 0 ? "No connection" : status === 429 ? "Too many requests, try again in a minute" : `Search failed (${status})`
  property string parseError: "Unexpected response"
  property string userAgent: ""
  property var curlArgs: []

  property string query: ""
  property string phase: "idle"
  property string error: ""
  property var results: []
  property int page: 1
  property bool hasMore: false
  property bool loadingMore: false
  property var downloads: ({})
  property int requestId: 0
  property int emptySkips: 5
  property var pending: null

  readonly property bool searching: phase === "searching"
  readonly property bool downloading: Object.keys(downloads).length > 0

  signal responded(int status)
  signal parseFailed
  signal downloaded(string key, string path, var item)
  signal downloadFailed(string key, string url, var item)

  function search(q) {
    query = q.trim();
    page = 1;
    results = [];
    hasMore = false;
    loadingMore = false;
    error = "";
    phase = "searching";
    fetchPage(1, 0, (res, err, p) => {
      if (!res) {
        error = err;
        phase = "error";
        return;
      }
      page = p;
      results = res.items;
      hasMore = res.more;
      phase = "results";
    });
  }

  function loadMore() {
    if (phase !== "results" || !hasMore || loadingMore)
      return;
    loadingMore = true;
    fetchPage(page + 1, 0, (res, err, p) => {
      loadingMore = false;
      if (!res)
        return;
      page = p;
      const seen = new Set(results.map(r => r.id));
      const fresh = res.items.filter(r => !seen.has(r.id));
      if (fresh.length > 0)
        results = results.concat(fresh);
      hasMore = res.more;
    });
  }

  function reset() {
    pending = null;
    phase = "idle";
    results = [];
    hasMore = false;
    loadingMore = false;
    error = "";
  }

  function fetchPage(p, skipped, done) {
    request(p, (res, err) => {
      if (res && res.items.length === 0 && res.more && skipped < emptySkips)
        fetchPage(p + 1, skipped + 1, done);
      else
        done(res, err, p);
    });
  }

  function request(p, done) {
    const id = ++requestId;
    pending = {
      id: id,
      done: done
    };
    const proc = fetcher.createObject(root, {
      requestId: id,
      url: urlFor(query, p)
    });
    proc.running = true;
  }

  function receive(id, status, body) {
    if (pending?.id !== id)
      return;
    const done = pending.done;
    pending = null;
    if (status !== 0)
      responded(status);
    if (status !== 200) {
      done(null, describe(status, body));
      return;
    }
    let res = null;
    try {
      res = parser(body);
    } catch (e) {
      parseFailed();
      done(null, parseError);
      return;
    }
    done(res, "");
  }

  function setDownloading(key, on) {
    const next = Object.assign({}, downloads);
    if (on)
      next[key] = true;
    else
      delete next[key];
    downloads = next;
  }

  function download(key, url, path, item) {
    if (downloads[key])
      return;
    setDownloading(key, true);
    const proc = downloader.createObject(root, {
      key: key,
      url: url,
      path: path,
      item: item ?? null
    });
    proc.running = true;
  }

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

  property Component downloader: Component {
    Process {
      id: dl

      property string key
      property string url
      property string path
      property var item

      command: ["sh", Paths.scripts + "/download.sh", url, path, root.userAgent]
      onExited: code => {
        root.setDownloading(dl.key, false);
        if (code === 0)
          root.downloaded(dl.key, dl.path, dl.item);
        else
          root.downloadFailed(dl.key, dl.url, dl.item);
        dl.destroy();
      }
    }
  }
}
