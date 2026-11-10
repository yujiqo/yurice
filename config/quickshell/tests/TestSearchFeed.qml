import QtQuick
import qs.components
import qs.services

Item {
  id: suite

  property var signals: []

  function page(ids, more) {
    return JSON.stringify({
      items: ids.map(id => ({
            id: id
          })),
      more: more
    });
  }

  function ids() {
    return feed.results.map(r => r.id);
  }

  SearchFeed {
    id: feed
    urlFor: (q, p) => `https://example.invalid/?q=${q}&page=${p}`
    parser: body => JSON.parse(body)
    onResponded: status => suite.signals = suite.signals.concat([`responded ${status}`])
    onParseFailed: suite.signals = suite.signals.concat(["parseFailed"])
    onDownloadFailed: (key, url, item) => suite.signals = suite.signals.concat([`downloadFailed ${key} ${item.id}`])
  }

  function test_search(t) {
    feed.search("  cats ");
    t.eq([feed.query, feed.phase, feed.searching], ["cats", "searching", true]);
    feed.receive(feed.requestId, 200, page(["a", "b"], true));
    t.eq([feed.phase, ids(), feed.hasMore, feed.page], ["results", ["a", "b"], true, 1]);
  }

  function test_loadMore_dedupes(t) {
    feed.loadMore();
    t.ok(feed.loadingMore);
    feed.loadMore();
    const id = feed.requestId;
    feed.receive(id, 200, page(["b", "c"], false));
    t.eq([ids(), feed.page, feed.hasMore, feed.loadingMore], [["a", "b", "c"], 2, false, false]);
    feed.loadMore();
    t.ok(!feed.loadingMore, "no more pages");
    t.eq(feed.requestId, id, "no request sent");
  }

  function test_loadMore_failureKeepsResults(t) {
    feed.search("x");
    feed.receive(feed.requestId, 200, page(["a"], true));
    feed.loadMore();
    feed.receive(feed.requestId, 0, "");
    t.eq([feed.phase, ids(), feed.page, feed.loadingMore, feed.error], ["results", ["a"], 1, false, ""]);
  }

  function test_staleResponseIgnored(t) {
    feed.search("old");
    const old = feed.requestId;
    feed.search("new");
    feed.receive(old, 200, page(["stale"], false));
    t.eq(feed.phase, "searching");
    feed.receive(feed.requestId, 200, page(["fresh"], false));
    t.eq(ids(), ["fresh"]);
  }

  function test_answeredOnce(t) {
    feed.search("once");
    const id = feed.requestId;
    feed.receive(id, 200, page(["a"], false));
    feed.receive(id, 0, "");
    t.eq([feed.phase, ids()], ["results", ["a"]]);
  }

  function test_resetCancels(t) {
    feed.search("gone");
    const id = feed.requestId;
    feed.reset();
    feed.receive(id, 200, page(["a"], false));
    t.eq([feed.phase, ids(), feed.hasMore, feed.loadingMore, feed.error], ["idle", [], false, false, ""]);
  }

  function test_errors(t) {
    signals = [];
    const cases = [[0, "No connection"], [429, "Too many requests, try again in a minute"], [500, "Search failed (500)"]];
    for (const [status, message] of cases) {
      feed.search("err");
      feed.receive(feed.requestId, status, "");
      t.eq([feed.phase, feed.error], ["error", message], `status ${status}`);
    }
    t.eq(signals, ["responded 429", "responded 500"]);
  }

  function test_parseFailure(t) {
    signals = [];
    feed.search("bad");
    feed.receive(feed.requestId, 200, "not json");
    t.eq([feed.phase, feed.error], ["error", "Unexpected response"]);
    t.eq(signals, ["responded 200", "parseFailed"]);
  }

  function test_download_1_bookkeeping(t) {
    signals = [];
    feed.download("k", "https://example.invalid/a.jpg", "/nonexistent/dir/a.jpg", {
      id: "item"
    });
    feed.download("k", "https://example.invalid/a.jpg", "/nonexistent/dir/a.jpg", {
      id: "again"
    });
    t.eq([feed.downloads, feed.downloading], [{
        k: true
      }, true]);
  }

  function test_download_2_wait(t) {
  }

  function test_download_3_failureReported(t) {
    t.eq([feed.downloads, feed.downloading], [{}, false]);
    t.eq(signals, ["downloadFailed k item"], "reported once with its item");
  }

  function test_danbooruSafeOnly_1_toggleWhileSearching(t) {
    Danbooru.query = "first";
    Danbooru.phase = "results";
    Danbooru.setSafeOnly(false);
    t.ok(!Danbooru.safeOnly);
  }

  function test_danbooruSafeOnly_2_survivesQueryWrite(t) {
    t.ok(!Danbooru.safeOnly, "safeOnly kept after the query write in the same tick");
    t.eq(Danbooru.query, "first");
  }

  function test_danbooruSafeOnly_3_restore(t) {
    Danbooru.phase = "idle";
    Danbooru.setSafeOnly(true);
    t.ok(Danbooru.safeOnly);
  }
}
