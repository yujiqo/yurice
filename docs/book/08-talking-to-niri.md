# 8. Talking to niri

The shell and the compositor are two separate programs. niri knows where every window is, which workspace is active, and which keyboard layout you're typing in. The shell wants to show all of that, and to change some of it when you click a workspace dot. This chapter builds [`services/Niri.qml`](../../config/quickshell/services/Niri.qml), the one place where they talk.

## niri's IPC

niri listens on a Unix socket. Its path is in the `$NIRI_SOCKET` environment variable, which every program started inside niri inherits. You talk to it in JSON, one message per line.

The `niri msg` command is a friendly client for that socket, and the best way to explore it. Try these in a terminal:

```sh
niri msg --json workspaces
niri msg --json windows
niri msg action focus-workspace 2
niri msg --json event-stream
```

The first two are requests: ask once, get one answer. The third is an action, which does something. The last one is different. It never exits. It prints the full current state first, then one line every time something changes. Open and close a window while it runs and watch the lines appear:

```json
{"WindowOpenedOrChanged":{"window":{"id":42,"title":"kitty","workspace_id":3,...}}}
{"WindowClosed":{"id":42}}
```

That event stream is what the shell is built on. Asking "what are the workspaces?" every second would be slow and always slightly out of date. Listening means the shell knows within a frame, and costs nothing while nothing happens.

## Step 1: listen

The listening part is a `Process` running `niri msg --json event-stream`, with a `SplitParser` that calls you back once per line:

```qml
  Process {
    command: ["niri", "msg", "--json", "event-stream"]
    running: true
    stdout: SplitParser {
      onRead: line => {
        try {
          root.handleEvent(JSON.parse(line));
        } catch (e) {
          console.warn("Niri: bad event line:", line);
        }
      }
    }
  }
```

[`services/Niri.qml:139-151`](../../config/quickshell/services/Niri.qml#L139-L151)

`StdioCollector` (chapter 7) waits for a process to finish. `SplitParser` is for processes that don't: it hands you each line as it arrives.

The `try` matters. A single bad line, maybe from a future niri version with a new event shape, must not break the stream for every line after it.

## Step 2: keep a copy of the state

`handleEvent` turns events into three properties:

```qml
  property var workspaces: []
  ...
  property var windows: ({})
  property var layoutNames: []
  property int layoutIndex: 0
```

[`services/Niri.qml:10-15`](../../config/quickshell/services/Niri.qml#L10-L15)

niri's events come in two kinds, and the service treats them differently.

Full snapshots like `WorkspacesChanged` and `WindowsChanged` contain the whole list. Just replace:

```qml
    if (event.WorkspacesChanged) {
      workspaces = event.WorkspacesChanged.workspaces;
    } ...
    } else if (event.WindowsChanged) {
      const map = {};
      for (const w of event.WindowsChanged.windows)
        map[w.id] = w;
      windows = map;
    }
```

Windows are stored as a map from id to window, because the other events refer to windows by id.

Small updates like `WindowClosed` or `WorkspaceActiveWindowChanged` describe one change. Apply it to a copy:

```qml
    } else if (event.WindowOpenedOrChanged) {
      const w = event.WindowOpenedOrChanged.window;
      windows = Object.assign({}, windows, {
        [w.id]: w
      });
    } else if (event.WindowClosed) {
      const next = Object.assign({}, windows);
      delete next[event.WindowClosed.id];
      windows = next;
    }
```

[`services/Niri.qml:75-137`](../../config/quickshell/services/Niri.qml#L75-L137)

### Why always a copy?

This is the most important QML lesson in this chapter. A `property var` only announces a change when it's assigned. If you change something inside it:

```qml
windows[w.id] = w;           // nothing updates
delete windows[id];          // nothing updates
```

QML doesn't notice, no `windowsChanged` signal fires, and every binding that reads `windows` keeps showing old data. Building a new object and assigning it (`windows = next`) fires the signal, and everything that depends on it updates. Every `var` property in every yurice service is updated this way. You saw the same pattern in `Settings.set()` in chapter 7.

### Merging an update into a workspace

`WorkspaceActivated` is the one tricky event. It says "workspace 2 is now active", but activating one workspace deactivates the others on the same monitor, and maybe moves focus too:

```qml
    } else if (event.WorkspaceActivated) {
      const {
        id,
        focused
      } = event.WorkspaceActivated;
      const target = workspaces.find(w => w.id === id);
      if (!target)
        return;
      workspaces = workspaces.map(w => Object.assign({}, w, {
          is_active: w.output === target.output ? w.id === id : w.is_active,
          is_focused: focused ? w.id === id : w.is_focused
        }));
    }
```

Each monitor has its own active workspace, but only one workspace in total is focused: the one on the monitor you're using.

## Step 3: answer questions

Raw state is rarely what a module wants. So the service answers the questions modules actually ask:

```qml
  readonly property string focusedOutput: workspaces.find(w => w.is_focused)?.output ?? ""
  readonly property string activeOutput: focusedOutput || (Quickshell.screens[0]?.name ?? "")
  ...
  function outputWorkspaces(output) {
    const target = output || focusedOutput;
    return workspaces.filter(w => w.output === target).sort((a, b) => a.idx - b.idx);
  }

  function outputCovered(output, width, height) {
    const ws = workspaces.find(w => w.output === output && w.is_active);
    const win = ws ? windows[ws.active_window_id] : null;
    const size = win?.layout?.tile_size;
    return !!size && !win.is_floating && size[0] >= width && size[1] >= height;
  }
```

[`services/Niri.qml:11-38`](../../config/quickshell/services/Niri.qml#L11-L38)

`activeOutput` is "the monitor you're on". It's how panels opened by keyboard appear on the right screen (chapter 9). Before the first event arrives it falls back to the first screen, so it's never empty.

`outputCovered` answers "is a tiled window as big as this monitor?". It looks up the active workspace on that monitor, then its active window, then that window's tile size. This is the function behind the bar's `covered` binding from chapter 2.

`outputCovered` is a function, but `Bar.qml` calls it inside a binding. QML records every property the function reads (`workspaces`, `windows`), so the binding still re-runs when either changes. Functions inside bindings are reactive too.

## Step 4: send actions

Clicking a workspace dot should switch to it. You could run `niri msg action focus-workspace …`, but starting a process for every click or scroll step is wasteful. Instead, the service opens its own connection to the socket:

```qml
  Socket {
    id: ipc
    path: Quickshell.env("NIRI_SOCKET")
    connected: true
    parser: SplitParser {}
  }
```

[`services/Niri.qml:64-69`](../../config/quickshell/services/Niri.qml#L64-L69)

and writes actions as JSON lines:

```qml
  function action(body) {
    if (!ipc.connected)
      ipc.connected = true;
    ipc.write(JSON.stringify({
      Action: body
    }) + "\n");
    ipc.flush();
  }
```

[`services/Niri.qml:19-26`](../../config/quickshell/services/Niri.qml#L19-L26)

The JSON shape mirrors the `niri msg action` command: `focus-workspace` becomes `FocusWorkspace`, and its argument becomes a field. Modules don't build JSON themselves, they call named helpers:

```qml
  function focusWorkspaceId(id) {
    action({
      FocusWorkspace: {
        reference: {
          Id: id
        }
      }
    });
  }
```

Note that the action changes nothing in the service. niri switches the workspace, sends `WorkspaceActivated` down the event stream, and that event updates `workspaces`. Same rule as chapter 7: ask the system to change, then let the change come back.

### Using it from the bar

[`modules/bar/Workspaces.qml`](../../config/quickshell/modules/bar/Workspaces.qml) is the workspace dots. A click calls the service:

```qml
          onClicked: Niri.focusWorkspace(root.output, dot.idx)
```

and scrolling over the island moves one workspace per wheel notch, with the same 120-unit counting as the slider:

```qml
    onWheel: event => {
      root.wheelDelta += event.angleDelta.y;
      while (root.wheelDelta >= 120) {
        root.wheelDelta -= 120;
        Niri.focusWorkspaceRelative(root.output, true);
      }
      ...
    }
```

[`modules/bar/Workspaces.qml:245-255`](../../config/quickshell/modules/bar/Workspaces.qml#L245-L255)

The dots themselves are kept in a `ListModel` that `sync()` updates whenever `Niri.workspaces` changes, instead of a plain `Repeater` over the array. Replacing the whole array would recreate every dot. Syncing a model adds and removes only the dots that changed, so new workspaces can animate in. Chapter 13 covers that island in full.

## Events that aren't state

Most events become properties. A keyboard layout switch is different: the current layout is state (`layoutIndex`), but "the layout just changed" is a moment you might want to announce. So the service does both:

```qml
    } else if (event.KeyboardLayoutSwitched) {
      layoutIndex = event.KeyboardLayoutSwitched.idx;
      layoutSwitched(layoutIndex);
    }
```

and the keyboard service turns that signal into a toast:

```qml
  Connections {
    target: Niri
    function onLayoutSwitched(index) {
      const name = Niri.layoutNames[index] ?? "";
      Notifications.notifyLocal("layout", "keyboard", name, "Layout " + root.shortName(name));
    }
  }
```

[`services/Keyboard.qml:21-27`](../../config/quickshell/services/Keyboard.qml#L21-L27)

Why a signal and not `onLayoutIndexChanged`? The first `KeyboardLayoutsChanged` at startup also sets `layoutIndex`, and you don't want a "Layout EN" toast every time the shell starts. The signal fires only on a real switch.

## One-off requests

Not everything needs the stream. The display service asks niri for monitor details with a plain process, at startup, when a monitor is plugged in or out, and after each change it makes:

```qml
  Process {
    id: reader
    command: ["niri", "msg", "-j", "outputs"]
    stdout: StdioCollector {
      onStreamFinished: root.parse(text)
    }
  }
```

[`services/Displays.qml:405-411`](../../config/quickshell/services/Displays.qml#L405-L411)

The lock screen turns monitors off with `niri msg action power-off-monitors`, and the power menu logs out with `niri msg action quit --skip-confirmation`. These happen rarely, so a process is simpler than the socket.

## Testing without niri

Because `handleEvent` is an ordinary function, the tests can feed it made-up events and check the result, with no compositor involved:

```qml
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
```

[`tests/TestNiri.qml`](../../config/quickshell/tests/TestNiri.qml)

This is a pattern worth copying in any service that parses outside data: keep the parsing in a plain function, and the logic becomes testable. Chapter 24 covers the test runner.

## The other direction

The shell also shapes niri, mostly through files rather than the socket. matugen writes `~/.cache/yurice/niri-colors.kdl`, which niri's config includes, and then tells niri to reload (chapter 3). The display settings write `custom/niri/outputs.kdl` (chapter 15). And niri's `animations { slowdown 1.7 }` is kept equal to the shell's `Theme.animSlowdown` by hand (chapter 5).

The shell can now hear niri and ask it for things. What's missing is the other way around: niri owns the keyboard, so how does `Mod+A` open the volume panel?
