import QtQuick
import qs.services

QtObject {
  function test_safeList(t) {
    const before = Wallpapers.safeFiles;
    Wallpapers.setSafe("/w/one.jpg", true);
    t.ok(Wallpapers.isSafe("/other/dir/one.jpg"), "safety is keyed by file name");
    Wallpapers.toggleSafe("/w/one.jpg");
    t.ok(!Wallpapers.isSafe("/w/one.jpg"));
    Wallpapers.setSafe("/w/two.jpg", true);
    Wallpapers.moveSafe("/w/two.jpg", "/w/three.jpg");
    t.ok(!Wallpapers.isSafe("/w/two.jpg"));
    t.ok(Wallpapers.isSafe("/w/three.jpg"));
    Wallpapers.moveSafe("/w/unsafe.jpg", "/w/four.jpg");
    t.ok(!Wallpapers.isSafe("/w/four.jpg"));
    Wallpapers.safeFiles = before;
  }

  function test_resolutions(t) {
    const before = Wallpapers.resolutions;
    Wallpapers.resolutions = {
      "/w/a.jpg": {
        w: 1920,
        h: 1080
      },
      "/w/b.jpg": {
        w: 3840,
        h: 2160
      },
      "/w/c.jpg": {
        w: 0,
        h: 0
      }
    };
    t.eq(Wallpapers.resolutionOf("/w/a.jpg"), "1920x1080");
    t.eq(Wallpapers.resolutionOf("/w/c.jpg"), "");
    t.eq(Wallpapers.resolutionOf("/w/none.jpg"), "");
    t.ok(Wallpapers.canUpscale("/w/a.jpg"));
    t.ok(!Wallpapers.canUpscale("/w/b.jpg"));
    t.ok(!Wallpapers.canUpscale("/w/c.jpg"));
    Wallpapers.resolutions = before;
  }

  function test_thumbs(t) {
    const before = Wallpapers.thumbs;
    const modifiedBefore = Wallpapers.modified;
    Wallpapers.modified = {
      "/w/a.jpg": 1
    };
    const file = Wallpapers.thumbPath("/w/a.jpg");
    t.ok(file.startsWith(Wallpapers.thumbDir + "/"));
    t.eq(Wallpapers.thumbPath("/w/a.jpg"), file, "key is stable");
    t.eq(Wallpapers.thumbFor("/w/a.jpg"), "", "no preview until generated");
    t.eq(Wallpapers.thumbFor(""), "");
    Wallpapers.thumbs = {
      [file]: true
    };
    t.eq(Wallpapers.thumbFor("/w/a.jpg"), Paths.fileUrl(file));
    Wallpapers.modified = {
      "/w/a.jpg": 2
    };
    t.ok(Wallpapers.thumbPath("/w/a.jpg") !== file, "edits invalidate the preview");
    t.eq(Wallpapers.thumbFor("/w/a.jpg"), "");
    Wallpapers.thumbs = before;
    Wallpapers.modified = modifiedBefore;
  }

  function test_weebModeDefaults(t) {
    t.eq(WeebMode.mode, "weeb");
    t.ok(!WeebMode.hidesWallpapers);
    t.ok(!WeebMode.hidesDanbooru);
  }
}
