import QtQuick
import qs.services

QtObject {
  function test_owner(t) {
    t.eq(Islands.owner("wifi"), "connectivity");
    t.eq(Islands.owner("brightness"), "levels");
    t.eq(Islands.owner("calendar"), "time");
    t.eq(Islands.owner("user"), "");
  }

  function test_hiddenRefusesPanels(t) {
    const before = Settings.values;
    Panels.close();
    Settings.values = Object.assign({}, before, {
      hiddenIslands: ["connectivity"]
    });
    t.ok(!Islands.enabled("connectivity"));
    t.ok(Islands.hidden.includes("connectivity"));
    Panels.open("bluetooth");
    t.eq(Panels.name, "");
    Panels.open("weather");
    t.eq(Panels.name, "weather");
    Panels.open("user");
    t.eq(Panels.name, "user");
    Panels.close();
    Settings.values = before;
    t.ok(Islands.enabled("connectivity"));
  }

  function test_invalidSetting(t) {
    const before = Settings.values;
    Settings.values = Object.assign({}, before, {
      hiddenIslands: "media"
    });
    t.eq(Settings.hiddenIslands, []);
    Settings.values = before;
  }

  function test_modeLabels(t) {
    t.eq([WeebMode.primaryLabel, WeebMode.secondaryLabel], ["Weeb", "Normie"]);
    t.eq(WeebMode.labelFor("normie"), "Normie");
    t.eq(WeebMode.label, "Weeb");
  }

  function test_modeIslandDefaults(t) {
    t.ok(WeebMode.islandHidden("danbooru"));
    t.ok(!WeebMode.islandHidden("weather"));
    t.ok(!WeebMode.hidesIsland("danbooru"));
    t.ok(Islands.shown("weather"));
  }
}
