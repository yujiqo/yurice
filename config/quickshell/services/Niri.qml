pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property var workspaces: []
  readonly property string focusedOutput: workspaces.find(w => w.is_focused)?.output ?? ""
  property var windows: ({})
  property var layoutNames: []
  property int layoutIndex: 0

  signal layoutSwitched(int index)

  function action(body) {
    if (!ipc.connected)
      ipc.connected = true;
    ipc.write(JSON.stringify({
      Action: body
    }) + "\n");
    ipc.flush();
  }

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

  function focusWorkspaceId(id) {
    action({
      FocusWorkspace: {
        reference: {
          Id: id
        }
      }
    });
  }

  function focusWorkspace(output, idx) {
    const ws = outputWorkspaces(output).find(w => w.idx === idx);
    if (ws)
      focusWorkspaceId(ws.id);
  }

  function focusWorkspaceRelative(output, up) {
    const list = outputWorkspaces(output);
    const i = list.findIndex(w => w.is_active);
    const next = list[i + (up ? -1 : 1)];
    if (i !== -1 && next)
      focusWorkspaceId(next.id);
  }

  Socket {
    id: ipc
    path: Quickshell.env("NIRI_SOCKET")
    connected: true
    parser: SplitParser {}
  }

  function patchWs(wsId, fields) {
    return workspaces.map(w => w.id === wsId ? Object.assign({}, w, fields) : w);
  }

  function handleEvent(event) {
    if (event.WorkspacesChanged) {
      workspaces = event.WorkspacesChanged.workspaces;
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
    } else if (event.WorkspaceActiveWindowChanged) {
      const {
        workspace_id,
        active_window_id
      } = event.WorkspaceActiveWindowChanged;
      workspaces = patchWs(workspace_id, {
        active_window_id
      });
    } else if (event.KeyboardLayoutsChanged) {
      const layouts = event.KeyboardLayoutsChanged.keyboard_layouts;
      layoutNames = layouts.names;
      layoutIndex = layouts.current_idx;
    } else if (event.KeyboardLayoutSwitched) {
      layoutIndex = event.KeyboardLayoutSwitched.idx;
      layoutSwitched(layoutIndex);
    } else if (event.WindowsChanged) {
      const map = {};
      for (const w of event.WindowsChanged.windows)
        map[w.id] = w;
      windows = map;
    } else if (event.WindowOpenedOrChanged) {
      const w = event.WindowOpenedOrChanged.window;
      windows = Object.assign({}, windows, {
        [w.id]: w
      });
    } else if (event.WindowClosed) {
      const next = Object.assign({}, windows);
      delete next[event.WindowClosed.id];
      windows = next;
    } else if (event.WindowLayoutsChanged) {
      const next = Object.assign({}, windows);
      for (const [id, layout] of event.WindowLayoutsChanged.changes) {
        if (next[id])
          next[id] = Object.assign({}, next[id], {
            layout
          });
      }
      windows = next;
    } else if (event.WorkspaceUrgencyChanged) {
      const {
        id,
        urgent
      } = event.WorkspaceUrgencyChanged;
      workspaces = patchWs(id, {
        is_urgent: urgent
      });
    }
  }

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
}
