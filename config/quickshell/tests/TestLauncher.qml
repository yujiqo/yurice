import QtQuick
import qs.services

QtObject {
  function test_scoreText(t) {
    t.eq(Launcher.scoreText("", "a"), 0);
    t.eq(Launcher.scoreText("Firefox", "firefox"), 120);
    t.eq(Launcher.scoreText("Firefox", "fire"), 100);
    t.eq(Launcher.scoreText("GNU Image Manipulation", "image"), 80);
    t.eq(Launcher.scoreText("Thunderbird", "derb"), 60);
    t.eq(Launcher.scoreText("Thunderbird", "tnb"), 20);
    t.eq(Launcher.scoreText("Thunderbird", "zzz"), 0);
  }

  function test_isMath(t) {
    for (const s of ["=2", "1+1", "2 * 3", "-1-2", "5!", "sqrt(2)", "pi", "10 km to mi", "3×4"])
      t.ok(Launcher.isMath(s), s);
    for (const s of ["=", "firefox", "42", "-5", "2024", "v2 player"])
      t.ok(!Launcher.isMath(s), s);
  }

  function test_parseClips(t) {
    Launcher.parseClips("12\thello world\n13\t[[ binary data 20 KiB png 100x50 ]]\n\n");
    t.eq(Launcher.clips, [{
        id: "12",
        preview: "hello world",
        isImage: false,
        ext: "",
        size: ""
      }, {
        id: "13",
        preview: "[[ binary data 20 KiB png 100x50 ]]",
        isImage: true,
        ext: "png",
        size: "100x50"
      }]);
    t.ok(!Launcher.clipsLoading);
    Launcher.parseClips("");
    t.eq(Launcher.clips, []);
  }

  function test_parseIcons(t) {
    Launcher.parseIcons(["/i/hicolor/48x48/apps/foo.png", "/i/hicolor/256x256/apps/foo.png", "/i/hicolor/scalable/apps/bar.svg", "/i/hicolor/64x64/apps/bar.png", "/i/hicolor/48x48/mimetypes/x.png"].join("\n"));
    t.eq(Launcher.localIcons, {
      foo: "/i/hicolor/256x256/apps/foo.png",
      bar: "/i/hicolor/scalable/apps/bar.svg"
    });
    t.eq(Launcher.iconFor("foo"), "file:///i/hicolor/256x256/apps/foo.png");
    t.eq(Launcher.iconFor("/abs/icon.png"), "file:///abs/icon.png");
    t.eq(Launcher.iconFor(""), "");
  }
}
