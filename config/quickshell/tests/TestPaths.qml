import Quickshell
import QtQuick
import qs.services
import qs.theme

QtObject {
  readonly property string home: Quickshell.env("HOME")

  function test_locations(t) {
    t.eq(Paths.home, home);
    t.eq(Paths.config, home + "/.config/yurice");
    t.eq(Paths.custom, home + "/.config/yurice/custom");
    t.eq(Paths.state, home + "/.local/state/yurice");
    t.eq(Paths.cache, home + "/.cache/yurice");
    t.ok(Paths.scripts.endsWith("/scripts"));
  }

  function test_expand(t) {
    t.eq(Paths.expand("~"), home);
    t.eq(Paths.expand("~/Pictures"), home + "/Pictures");
    t.eq(Paths.expand("~user/x"), "~user/x");
    t.eq(Paths.expand("/abs/~/x"), "/abs/~/x");
  }

  function test_display(t) {
    t.eq(Paths.display(home), "~");
    t.eq(Paths.display(home + "/Pictures"), "~/Pictures");
    t.eq(Paths.display(home + "x/Pictures"), home + "x/Pictures");
    t.eq(Paths.display("/etc/x"), "/etc/x");
  }

  function test_fileUrl(t) {
    t.eq(Paths.fileUrl(""), "");
    t.eq(Paths.fileUrl("/a/b.png"), "file:///a/b.png");
    t.eq(Paths.fileUrl("/my dir/#1 50%.jpg"), "file:///my%20dir/%231%2050%25.jpg");
  }

  function test_baseName(t) {
    t.eq(Paths.baseName("/a/b/c.jpg"), "c.jpg");
    t.eq(Paths.baseName("c.jpg"), "c.jpg");
    t.eq(Paths.baseName("/a/b/"), "");
  }

  function test_dirName(t) {
    t.eq(Paths.dirName("/a/b/c.jpg"), "/a/b");
    t.eq(Paths.dirName("/c.jpg"), "");
    t.eq(Paths.dirName("c.jpg"), "");
  }

  function test_fileLocations(t) {
    t.eq(Settings.directory, home + "/.config/yurice/custom/quickshell");
    t.eq(Settings.avatarPath, home + "/.config/yurice/custom/avatars/weeb.jpg");
    t.eq(Settings.normieAvatarPath, home + "/.config/yurice/custom/avatars/normie.jpg");
    t.eq(Displays.kdlPath, home + "/.config/yurice/custom/niri/outputs.kdl");
    t.eq(Launcher.cacheDir, home + "/.cache/yurice/clip");
    t.eq(WallpaperPublish.cacheFile, home + "/.cache/yurice/wallpaper-cache.jpg");
    t.eq(Theme.paletteFile, home + "/.cache/yurice/colors.json");
  }
}
