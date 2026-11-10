import Quickshell
import QtQuick
import qs.services

QtObject {
  function test_userName(t) {
    t.eq(Session.userName, Quickshell.env("USER"));
  }

  function test_sharedRoot(t) {
    t.eq(Paths.shared, Quickshell.env("YURICE_STATE_ROOT") || "/var/lib/yurice");
    t.eq(WallpaperPublish.publishDir, `${Paths.shared}/users/${Session.userName}`);
  }

  function test_avatarFollowsMode(t) {
    t.eq(WeebMode.mode, "weeb");
    t.eq(WeebMode.avatar, Settings.avatarPath);
    t.eq(WallpaperPublish.avatar, WeebMode.avatar);
  }

  function test_keyboardShortName(t) {
    t.eq(Keyboard.shortName("English (US)"), "EN");
    t.eq(Keyboard.shortName("Russian"), "RU");
    t.eq(Keyboard.shortName("ge"), "GE");
  }

  function test_launcherToggleClipboard(t) {
    Launcher.close();
    Launcher.toggleClipboard();
    t.eq(Launcher.mode, "clipboard");
    Launcher.toggleClipboard();
    t.eq(Launcher.mode, "");
    Launcher.open("launcher");
    Launcher.toggleClipboard();
    t.eq(Launcher.mode, "clipboard", "switches from launcher to clipboard");
    Launcher.close();
  }

  function test_screenshotPaths(t) {
    t.eq(Screenshot.clipFile, Paths.cache + "/screenshot.png");
    t.ok(Screenshot.outputPath().startsWith(Settings.screenshotDirectory + "/Screenshot from "));
  }

  function test_brightnessDetection(t) {
    t.ok(Brightness.backlightDir === "" || Brightness.backlightDir.startsWith("/sys/class/backlight/"));
    t.ok(!Brightness.available || Brightness.backlightDir !== "");
  }
}
