import Quickshell
import QtQuick
import qs.services

QtObject {
  readonly property string home: Quickshell.env("HOME")

  function test_parse(t) {
    t.eq(Settings.parse(""), {});
    t.eq(Settings.parse("  \n"), {});
    t.eq(Settings.parse("not json"), {});
    t.eq(Settings.parse('{"clock24h": false}'), {
      clock24h: false
    });
  }

  function test_defaults(t) {
    t.eq(Settings.wallpaperDirectory, home + "/Pictures/Wallpapers");
    t.eq(Settings.danbooruDirectory, home + "/Pictures/Danbooru");
    t.eq(Settings.screenshotDirectory, home + "/Pictures/Screenshots");
    t.eq(Settings.idleScreenOff, 10);
    t.eq(Settings.idleLock, 30);
  }

  function test_timeFormats(t) {
    const before = Settings.values;
    const cases = [[true, false, "HH:mm", "HH:mm"], [true, true, "HH:mm:ss", "HH:mm"], [false, false, "h:mm AP", "h:mm AP"], [false, true, "h:mm:ss AP", "h:mm AP"]];
    for (const [h24, seconds, full, short] of cases) {
      Settings.values = Object.assign({}, before, {
        clock24h: h24,
        clockSeconds: seconds
      });
      t.eq([Settings.timeFormat, Settings.shortTimeFormat], [full, short], `24h=${h24} seconds=${seconds}`);
    }
    Settings.values = before;
  }
}
