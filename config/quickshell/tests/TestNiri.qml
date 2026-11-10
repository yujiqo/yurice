import Quickshell
import QtQuick
import qs.services

QtObject {
  function ws(id, output, idx, extra) {
    return Object.assign({
      id: id,
      output: output,
      idx: idx,
      is_active: false,
      is_focused: false,
      is_urgent: false,
      active_window_id: null
    }, extra ?? {});
  }

  function reset() {
    Niri.workspaces = [];
    Niri.windows = {};
    Niri.layoutNames = [];
    Niri.layoutIndex = 0;
  }

  function seed() {
    reset();
    Niri.handleEvent({
      WorkspacesChanged: {
        workspaces: [ws(1, "A", 1, {
            is_active: true,
            is_focused: true,
            active_window_id: 10
          }), ws(2, "A", 2), ws(3, "B", 1, {
            is_active: true
          })]
      }
    });
  }

  function test_workspacesChanged(t) {
    seed();
    t.eq(Niri.workspaces.length, 3);
    t.eq(Niri.focusedOutput, "A");
    t.eq(Niri.activeOutput, "A");
    reset();
    t.eq(Niri.focusedOutput, "");
    t.eq(Niri.activeOutput, Quickshell.screens[0]?.name ?? "", "falls back to the first screen");
  }

  function test_workspaceActivated_sameOutput(t) {
    seed();
    Niri.handleEvent({
      WorkspaceActivated: {
        id: 2,
        focused: true
      }
    });
    const flags = Niri.workspaces.map(w => [w.id, w.is_active, w.is_focused]);
    t.eq(flags, [[1, false, false], [2, true, true], [3, true, false]]);
    reset();
  }

  function test_workspaceActivated_unfocused(t) {
    seed();
    Niri.handleEvent({
      WorkspaceActivated: {
        id: 2,
        focused: false
      }
    });
    const flags = Niri.workspaces.map(w => [w.id, w.is_active, w.is_focused]);
    t.eq(flags, [[1, false, true], [2, true, false], [3, true, false]]);
    reset();
  }

  function test_workspaceActivated_unknownIgnored(t) {
    seed();
    const before = Niri.workspaces;
    Niri.handleEvent({
      WorkspaceActivated: {
        id: 99,
        focused: true
      }
    });
    t.ok(Niri.workspaces === before);
    reset();
  }

  function test_activeWindowAndUrgency(t) {
    seed();
    Niri.handleEvent({
      WorkspaceActiveWindowChanged: {
        workspace_id: 2,
        active_window_id: 7
      }
    });
    Niri.handleEvent({
      WorkspaceUrgencyChanged: {
        id: 3,
        urgent: true
      }
    });
    t.eq(Niri.workspaces.find(w => w.id === 2).active_window_id, 7);
    t.eq(Niri.workspaces.find(w => w.id === 3).is_urgent, true);
    t.eq(Niri.workspaces.find(w => w.id === 1).active_window_id, 10);
    reset();
  }

  function test_keyboardLayouts(t) {
    reset();
    let switched = -1;
    const listener = i => switched = i;
    Niri.layoutSwitched.connect(listener);
    Niri.handleEvent({
      KeyboardLayoutsChanged: {
        keyboard_layouts: {
          names: ["English (US)", "Russian"],
          current_idx: 0
        }
      }
    });
    t.eq(Niri.layoutNames, ["English (US)", "Russian"]);
    t.eq(switched, -1, "initial layouts don't emit a switch");
    Niri.handleEvent({
      KeyboardLayoutSwitched: {
        idx: 1
      }
    });
    t.eq(Niri.layoutIndex, 1);
    t.eq(switched, 1);
    Niri.layoutSwitched.disconnect(listener);
    reset();
  }

  function test_windows(t) {
    reset();
    Niri.handleEvent({
      WindowsChanged: {
        windows: [{
            id: 10,
            is_floating: false
          }, {
            id: 11,
            is_floating: true
          }]
      }
    });
    t.eq(Object.keys(Niri.windows).sort(), ["10", "11"]);
    Niri.handleEvent({
      WindowOpenedOrChanged: {
        window: {
          id: 12,
          is_floating: false
        }
      }
    });
    Niri.handleEvent({
      WindowClosed: {
        id: 11
      }
    });
    t.eq(Object.keys(Niri.windows).sort(), ["10", "12"]);
    Niri.handleEvent({
      WindowLayoutsChanged: {
        changes: [[10, {
              tile_size: [100, 50]
            }], [99, {
              tile_size: [1, 1]
            }]]
      }
    });
    t.eq(Niri.windows[10].layout.tile_size, [100, 50]);
    t.ok(Niri.windows[99] === undefined, "unknown window is not created");
    reset();
  }

  function test_outputWorkspaces(t) {
    seed();
    Niri.workspaces = Niri.workspaces.slice().reverse();
    t.eq(Niri.outputWorkspaces("A").map(w => w.id), [1, 2]);
    t.eq(Niri.outputWorkspaces("").map(w => w.id), [1, 2], "defaults to focused output");
    t.eq(Niri.outputWorkspaces("B").map(w => w.id), [3]);
    reset();
  }

  function test_outputCovered(t) {
    seed();
    Niri.windows = {
      10: {
        id: 10,
        is_floating: false,
        layout: {
          tile_size: [1920, 1080]
        }
      }
    };
    t.ok(Niri.outputCovered("A", 1920, 1080));
    t.ok(!Niri.outputCovered("A", 2560, 1440));
    t.ok(!Niri.outputCovered("B", 1920, 1080), "no active window");
    Niri.windows = {
      10: {
        id: 10,
        is_floating: true,
        layout: {
          tile_size: [1920, 1080]
        }
      }
    };
    t.ok(!Niri.outputCovered("A", 1920, 1080), "floating windows never cover");
    reset();
  }
}
