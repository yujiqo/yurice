import QtQuick
import qs.services

QtObject {
  function test_wallSearch_buildUrl(t) {
    t.eq(WallSearch.hasApiKey, false);
    t.eq(WallSearch.buildUrl("cat girl", 2), `https://wallhaven.cc/api/v1/search?q=cat%20girl&categories=111&purity=100&sorting=relevance&page=2&atleast=${WallSearch.resolution}`);
  }

  function test_wallSearch_toplist_1_set(t) {
    WallSearch.setFilter("sorting", "toplist");
    t.eq(WallSearch.buildUrl("x", 1), `https://wallhaven.cc/api/v1/search?q=x&categories=111&purity=100&sorting=toplist&page=1&topRange=1y&atleast=${WallSearch.resolution}`);
  }

  function test_wallSearch_toplist_2_restore(t) {
    WallSearch.setFilter("sorting", "relevance");
    t.eq(WallSearch.sorting, "relevance");
  }

  function test_wallSearch_atleast_1_off(t) {
    WallSearch.setFilter("atleast", false);
    t.eq(WallSearch.buildUrl("x", 1), "https://wallhaven.cc/api/v1/search?q=x&categories=111&purity=100&sorting=relevance&page=1");
  }

  function test_wallSearch_atleast_2_restore(t) {
    WallSearch.setFilter("atleast", true);
    t.ok(WallSearch.atleast);
  }

  function test_wallSearch_parse(t) {
    const res = WallSearch.parse(JSON.stringify({
      data: [{
          id: "abc",
          thumbs: {
            large: "https://t/abc.jpg"
          },
          path: "https://w/abc.png",
          resolution: "1920x1080",
          purity: "sfw",
          category: "anime"
        }],
      meta: {
        current_page: 1,
        last_page: 3
      }
    }));
    t.eq(res, {
      items: [{
          id: "abc",
          thumb: "https://t/abc.jpg",
          full: "https://w/abc.png",
          resolution: "1920x1080",
          ext: "png",
          purity: "sfw",
          category: "anime"
        }],
      more: true
    });
    t.eq(WallSearch.parse("{}"), {
      items: [],
      more: false
    });
  }

  function test_wallSearch_toggleBit_1(t) {
    WallSearch.toggleBit("categories", 0);
    t.eq(WallSearch.categories, "011");
  }

  function test_wallSearch_toggleBit_2(t) {
    WallSearch.toggleBit("categories", 1);
    t.eq(WallSearch.categories, "001");
  }

  function test_wallSearch_toggleBit_3_lastBitStays(t) {
    WallSearch.toggleBit("categories", 2);
    t.eq(WallSearch.categories, "001");
  }

  function test_wallSearch_toggleBit_4_restore(t) {
    WallSearch.setFilter("categories", "111");
    t.eq(WallSearch.categories, "111");
  }

  function test_wallSearch_pathFor(t) {
    t.eq(WallSearch.pathFor({
      id: "abc",
      ext: "jpg"
    }), Wallpapers.directory + "/wallhaven-abc.jpg");
  }

  function test_danbooru_buildUrl(t) {
    t.ok(Danbooru.safeOnly);
    t.eq(Danbooru.buildUrl("1girl ", 3), "https://danbooru.donmai.us/posts.json?limit=30&page=3&tags=1girl%20%20rating%3Ag");
    t.eq(Danbooru.buildUrl("", 1), "https://danbooru.donmai.us/posts.json?limit=30&page=1&tags=rating%3Ag");
  }

  function test_danbooru_parse(t) {
    const post = {
      id: 5,
      file_url: "https://d/5.png",
      file_ext: "png",
      preview_file_url: "https://d/p5.jpg",
      image_width: 800,
      image_height: 600,
      media_asset: {
        variants: [{
            type: "360x360",
            url: "https://d/360.jpg"
          }, {
            type: "720x720",
            url: "https://d/720.webp"
          }]
      }
    };
    const res = Danbooru.parse(JSON.stringify([post, {
        id: 6,
        file_url: "https://d/6.mp4",
        file_ext: "mp4"
      }, {
        id: 7,
        file_ext: "png"
      }]));
    t.eq(res, {
      items: [{
          id: "5",
          thumb: "https://d/720.webp",
          full: "https://d/5.png",
          resolution: "800x600",
          ext: "png"
        }],
      more: false
    });
    const fallback = Danbooru.parse(JSON.stringify([Object.assign({}, post, {
        media_asset: null
      })]));
    t.eq(fallback.items[0].thumb, "https://d/p5.jpg");
    let threw = false;
    try {
      Danbooru.parse('{"success": false}');
    } catch (e) {
      threw = true;
    }
    t.ok(threw, "non-array body throws");
  }

  function test_danbooru_describe(t) {
    t.eq(Danbooru.describe(422, '{"message": "too many tags"}'), "too many tags");
    t.eq(Danbooru.describe(0, ""), "No connection");
    t.eq(Danbooru.describe(401, "<html>"), "Wrong username or API key");
    t.eq(Danbooru.describe(429, ""), "Too many requests, try again in a minute");
    t.eq(Danbooru.describe(503, ""), "Danbooru is unavailable right now");
    t.eq(Danbooru.describe(404, ""), "Search failed (404)");
  }

  function test_danbooru_fileName(t) {
    t.eq(Danbooru.fileName({
      id: "5",
      ext: "png"
    }), "danbooru-5.png");
  }
}
