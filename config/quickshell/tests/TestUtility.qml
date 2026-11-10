import QtQuick
import qs.components

QtObject {
  function test_seg(t) {
    t.eq(Utility.seg("wifi", "Home", "#fff"), {
      icon: "wifi",
      label: "Home",
      color: "#fff"
    });
  }

  function test_pick(t) {
    const steps = [[80, "high"], [40, "mid"]];
    t.eq(Utility.pick(90, steps, "low"), "high");
    t.eq(Utility.pick(80, steps, "low"), "high");
    t.eq(Utility.pick(79, steps, "low"), "mid");
    t.eq(Utility.pick(40, steps, "low"), "mid");
    t.eq(Utility.pick(39, steps, "low"), "low");
  }

  function test_fileUrl(t) {
    t.eq(Utility.fileUrl(""), "");
    t.eq(Utility.fileUrl("/a/b.png"), "file:///a/b.png");
    t.eq(Utility.fileUrl("/my dir/#1 50%.jpg"), "file:///my%20dir/%231%2050%25.jpg");
  }

  function test_sameItems(t) {
    t.ok(Utility.sameItems([], []));
    t.ok(Utility.sameItems([1, "a"], [1, "a"]));
    t.ok(!Utility.sameItems([1, 2], [2, 1]));
    t.ok(!Utility.sameItems([1], [1, 1]));
  }
}
