import QtQuick
import qs.services

QtObject {
  function test_openCloseToggle(t) {
    Panels.close();
    Panels.open("bogus");
    t.eq(Panels.name, "");
    Panels.open("media");
    t.eq(Panels.name, "media");
    t.ok(Panels.keyboard);
    Panels.toggle("media");
    t.eq(Panels.name, "");
    Panels.toggle("calendar");
    Panels.toggle("weather");
    t.eq(Panels.name, "weather");
    Panels.close();
  }

  function test_sessionToggle(t) {
    Session.close();
    Session.toggle();
    t.ok(Session.isOpen);
    Session.toggle();
    t.ok(!Session.isOpen);
  }

  function test_launcherToggle(t) {
    Launcher.close();
    Launcher.toggle();
    t.eq(Launcher.mode, "launcher");
    Launcher.calcQuery = "1+1";
    Launcher.toggle();
    t.eq([Launcher.mode, Launcher.calcQuery], ["", ""]);
  }
}
