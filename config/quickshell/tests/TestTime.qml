import QtQuick
import qs.components
import qs.services

QtObject {
  function at(h, m) {
    return new Date(2024, 4, 10, h, m, 30);
  }

  function test_formatDuration(t) {
    t.eq(Utility.formatDuration(0), "0m");
    t.eq(Utility.formatDuration(59 * 60), "59m");
    t.eq(Utility.formatDuration(3600), "1h 0m");
    t.eq(Utility.formatDuration(3720), "1h 2m");
    t.eq(Utility.formatDuration(89), "1m");
    t.eq(Utility.formatDuration(-5), "0m");
    t.eq(Utility.formatDuration(26 * 3600 + 180), "1d 2h 3m");
  }

  function test_isLightAt_daytimeWindow(t) {
    t.eq(ThemeMode.lightStart, 480);
    t.eq(ThemeMode.lightEnd, 960);
    t.ok(!ThemeMode.isLightAt(at(7, 59)));
    t.ok(ThemeMode.isLightAt(at(8, 0)));
    t.ok(ThemeMode.isLightAt(at(15, 59)));
    t.ok(!ThemeMode.isLightAt(at(16, 0)));
  }

  function test_nextSwitch(t) {
    const next = ThemeMode.nextSwitch(at(7, 0));
    t.eq([next.getHours(), next.getMinutes(), next.getSeconds()], [8, 0, 0]);
    const evening = ThemeMode.nextSwitch(at(16, 0));
    t.eq([evening.getDate(), evening.getHours(), evening.getMinutes()], [11, 8, 0], "rolls over midnight");
    const exact = ThemeMode.nextSwitch(at(8, 0));
    t.eq([exact.getHours(), exact.getMinutes()], [16, 0], "switch at current minute is not reported");
  }

  function test_minutesOf(t) {
    t.eq(ThemeMode.minutesOf(at(13, 37)), 13 * 60 + 37);
  }
}
