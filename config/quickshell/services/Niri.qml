pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property var workspaces: []

  function _onOutput(output, action) {
    if (output === "") {
      Quickshell.execDetached(["niri", "msg", "action", ...action]);
      return;
    }
    Quickshell.execDetached(["sh", "-c", 'niri msg action focus-monitor "$1" && shift && niri msg action "$@"', "sh", output, ...action]);
  }

  function focusWorkspace(output, idx) {
    _onOutput(output, ["focus-workspace", String(idx)]);
  }

  function focusWorkspaceRelative(output, up) {
    _onOutput(output, [up ? "focus-workspace-up" : "focus-workspace-down"]);
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
