pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property var workspaces: []
  readonly property string focusedOutput: workspaces.find(w => w.is_focused)?.output ?? ""

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
