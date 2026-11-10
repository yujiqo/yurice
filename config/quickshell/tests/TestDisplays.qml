import QtQuick
import qs.services

QtObject {
  function st(x, y, extra) {
    return Object.assign({
      enabled: true,
      width: 1920,
      height: 1080,
      refresh: 60000,
      scale: 1,
      transform: "normal",
      x: x,
      y: y
    }, extra ?? {});
  }

  function test_normalizeTransform(t) {
    t.eq(Displays.normalizeTransform(undefined), "normal");
    t.eq(Displays.normalizeTransform("Normal"), "normal");
    t.eq(Displays.normalizeTransform("_90"), "90");
    t.eq(Displays.normalizeTransform("Flipped"), "flipped");
    t.eq(Displays.normalizeTransform("Flipped90"), "flipped-90");
  }

  function test_modeText(t) {
    t.eq(Displays.modeText(st(0, 0, {
      refresh: 143981
    })), "1920x1080@143.981");
  }

  function test_sizeOf(t) {
    t.eq(Displays.sizeOf(st(0, 0)), {
      width: 1920,
      height: 1080
    });
    t.eq(Displays.sizeOf(st(0, 0, {
      scale: 1.5
    })), {
      width: 1280,
      height: 720
    });
    t.eq(Displays.sizeOf(st(0, 0, {
      transform: "flipped-270",
      scale: 0
    })), {
      width: 1080,
      height: 1920
    });
  }

  function test_overlaps(t) {
    const a = {
      x: 0,
      y: 0,
      width: 10,
      height: 10
    };
    t.ok(Displays.overlaps(a, {
      x: 5,
      y: 5,
      width: 10,
      height: 10
    }));
    t.ok(!Displays.overlaps(a, {
      x: 10,
      y: 0,
      width: 10,
      height: 10
    }), "touching edges don't overlap");
  }

  function test_snapIn_alone(t) {
    t.eq(Displays.snapIn({
      A: st(0, 0)
    }, "A", 12.4, 7.6), {
      x: 12,
      y: 8
    });
  }

  function test_snapIn_rightEdge(t) {
    const states = {
      A: st(0, 0),
      B: st(0, 0, {
        width: 2560,
        height: 1440
      })
    };
    t.eq(Displays.snapIn(states, "B", 1900, 30), {
      x: 1920,
      y: 0
    }, "snaps to right edge and aligns top");
    t.eq(Displays.snapIn(states, "B", -2500, 0), {
      x: -2560,
      y: 0
    }, "snaps to left edge");
    t.eq(Displays.snapIn(states, "B", 0, 1000), {
      x: 0,
      y: 1080
    }, "snaps below");
  }

  function test_commandsFor(t) {
    t.eq(Displays.commandsFor({
      "DP-1": st(0, 0),
      "HDMI-A-1": st(0, 0, {
        enabled: false
      })
    }).split("\n"), ["niri msg output 'DP-1' on", "niri msg output 'DP-1' mode 1920x1080@60.000", "niri msg output 'DP-1' scale 1", "niri msg output 'DP-1' transform normal", "niri msg output 'DP-1' position set -- 0 0", "niri msg output 'HDMI-A-1' off"]);
  }

  function test_parse(t) {
    Displays.parse(JSON.stringify({
      "DP-1": {
        name: "DP-1",
        make: "Dell",
        model: "U2720Q",
        modes: [{
            width: 3840,
            height: 2160,
            refresh_rate: 60000,
            is_preferred: true
          }, {
            width: 1920,
            height: 1080,
            refresh_rate: 60000,
            is_preferred: false
          }],
        current_mode: 0,
        logical: {
          x: 1920,
          y: 0,
          scale: 2,
          transform: "Normal"
        }
      },
      "HDMI-A-1": {
        name: "HDMI-A-1",
        make: "Unknown",
        model: "Unknown",
        modes: [{
            width: 1920,
            height: 1080,
            refresh_rate: 60000,
            is_preferred: true
          }],
        current_mode: null,
        logical: null
      }
    }));
    t.eq(Displays.error, "");
    t.eq(Displays.outputs.map(o => [o.name, o.title, o.enabled, o.mode.width, o.scale, o.x]), [["HDMI-A-1", "HDMI-A-1", false, 1920, 1, 0], ["DP-1", "Dell U2720Q", true, 3840, 2, 1920]]);
    t.eq(Displays.selected, "HDMI-A-1");
    t.ok(!Displays.dirty);
    t.eq(Displays.enabledCount, 1);
    Displays.parse("garbage");
    t.eq(Displays.error, "Couldn't read outputs from niri");
  }

  function test_update_shiftsNeighbours(t) {
    Displays.outputs = [];
    Displays.draft = {
      A: st(0, 0),
      B: st(1920, 0)
    };
    Displays.update("A", {
      width: 2560,
      height: 1440
    });
    t.eq([Displays.draft.B.x, Displays.draft.B.y], [2560, 0]);
    Displays.draft = {};
  }

  function test_move_snaps(t) {
    Displays.outputs = [];
    Displays.draft = {
      A: st(0, 0),
      B: st(1920, 0)
    };
    Displays.move("B", 1950, 40);
    t.eq([Displays.draft.B.x, Displays.draft.B.y], [1920, 0]);
    Displays.draft = {};
  }
}
