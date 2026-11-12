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

  property var prepared: []

  SearchFeed {
    id: planned
    urlFor: (q, p) => `https://example.invalid/?q=${q}&page=${p}`
    parser: body => JSON.parse(body)
    prepare: (q, done) => suite.prepared = suite.prepared.concat([{
          query: q,
          done: done
        }])
  }

  function test_prepare_runsBeforeFirstPage(t) {
    prepared = [];
    planned.search("old");
    const stale = planned.requestId;
    planned.search(" cats ");
    t.eq([planned.phase, prepared.map(p => p.query)], ["searching", ["old", "cats"]]);
    planned.pageCount = 2;
    prepared[1].done();
    t.ok(planned.requestId > stale + 1, "first page requested after prepare");
    const first = planned.requestId;
    prepared[0].done();
    t.eq(planned.requestId, first, "stale prepare ignored");
    planned.receive(first, 200, page(["a"], true));
    t.eq([planned.phase, planned.hasMore], ["results", true]);
    planned.loadMore();
    planned.receive(planned.requestId, 200, page(["b"], true));
    t.eq([planned.page, planned.hasMore], [2, false], "pageCount caps paging");
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

  function test_emptyPagesSkipped(t) {
    feed.search("sparse");
    feed.receive(feed.requestId, 200, page([], true));
    t.eq(feed.phase, "searching", "keeps going past an empty page");
    feed.receive(feed.requestId, 200, page(["a"], true));
    t.eq([feed.phase, ids(), feed.page], ["results", ["a"], 2]);
    feed.loadMore();
    for (let i = 0; i <= feed.emptySkips; i++)
      feed.receive(feed.requestId, 200, page([], true));
    t.eq([ids(), feed.page, feed.loadingMore, feed.hasMore], [["a"], 2 + feed.emptySkips + 1, false, true]);
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
    t.eq(Danbooru.phase, "results", "no new search until the next one");
    t.ok(Danbooru.buildUrl("x", 2).endsWith("rating%3Ag"), "current search keeps its rating");
  }

  function test_danbooruSafeOnly_2_survivesQueryWrite(t) {
    t.ok(!Danbooru.safeOnly, "safeOnly kept after the query write in the same tick");
    t.eq(Danbooru.query, "first");
    Danbooru.setSorting("newest");
    t.eq([Danbooru.phase, Danbooru.sorting], ["results", "newest"], "sorting waits for the next search");
  }

  function test_danbooruSafeOnly_3_restore(t) {
    Danbooru.setSorting("random");
    t.eq(Danbooru.sorting, "random");
  }

  function test_danbooruSafeOnly_4_restore(t) {
    Danbooru.phase = "idle";
    Danbooru.setSafeOnly(true);
    t.ok(Danbooru.safeOnly);
  }
}
