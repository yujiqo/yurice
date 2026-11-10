import QtQuick
import qs.services

QtObject {
  property var saved: null

  function test_1_initialFormat(t) {
    t.eq([Clock.timeFormat, Clock.shortTimeFormat, Clock.clock24h, Clock.fade], [Settings.timeFormat, Settings.shortTimeFormat, Settings.clock24h, 1]);
  }

  function test_2_formatChangeIsDeferred(t) {
    saved = Settings.values;
    Settings.values = Object.assign({}, saved, {
      clock24h: false
    });
    t.eq(Settings.timeFormat, "h:mm AP");
    t.eq(Clock.timeFormat, "HH:mm", "shown format waits for the fade-out");
    Settings.values = saved;
  }
}
