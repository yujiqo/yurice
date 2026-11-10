pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property var sections: []

  readonly property var keyNames: ({
      "Mod": "Super",
      "Slash": "/",
      "BracketLeft": "[",
      "BracketRight": "]",
      "Minus": "-",
      "Equal": "=",
      "Comma": ",",
      "Period": ".",
      "Semicolon": ";",
      "Apostrophe": "'",
      "Backslash": "\\",
      "Grave": "`",
      "Escape": "Esc",
      "Print": "PrtSc",
      "Return": "Enter",
      "Delete": "Del",
      "Page_Up": "PgUp",
      "Page_Down": "PgDn",
      "WheelScrollUp": "Wheel ↑",
      "WheelScrollDown": "Wheel ↓",
      "XF86AudioRaiseVolume": "Vol +",
      "XF86AudioLowerVolume": "Vol −",
      "XF86AudioMute": "Mute",
      "XF86AudioMicMute": "Mic mute",
      "XF86AudioPlay": "Play",
      "XF86AudioStop": "Stop",
      "XF86AudioPrev": "Prev",
      "XF86AudioNext": "Next",
      "XF86MonBrightnessUp": "Bright +",
      "XF86MonBrightnessDown": "Bright −"
    })

  function keysOf(combo) {
    return combo.split("+").map(k => keyNames[k] ?? k.replace(/^XF86/, ""));
  }

  function humanize(action) {
    const words = action.trim().replace(/;$/, "").split(/\s+/);
    const name = words[0].replace(/-/g, " ");
    const args = words.slice(1).map(w => w.replace(/^"|"$/g, "")).join(" ");
    const text = args !== "" ? name + " " + args : name;
    return text.charAt(0).toUpperCase() + text.slice(1);
  }

  function parse(text) {
    const result = [];
    let current = null;
    const section = /^\s*\/\/\s*section:\s*(.+?)\s*$/;
    const bind = /^\s*([A-Za-z0-9_+]+)((?:\s+[a-z-]+=(?:"(?:[^"\\]|\\.)*"|\S+))*)\s*\{\s*(.*?)\s*\}\s*$/;
    const titleAttr = /hotkey-overlay-title=(null|"((?:[^"\\]|\\.)*)")/;
    for (const line of text.split("\n")) {
      const s = line.match(section);
      if (s) {
        current = {
          title: s[1],
          binds: []
        };
        result.push(current);
        continue;
      }
      if (/^\s*\/\//.test(line))
        continue;
      const b = line.match(bind);
      if (!b)
        continue;
      const action = b[3].replace(/;\s*$/, "");
      if (action.startsWith("show-hotkey-overlay"))
        continue;
      const t = b[2].match(titleAttr);
      if (t && t[1] === "null")
        continue;
      if (!current) {
        current = {
          title: "General",
          binds: []
        };
        result.push(current);
      }
      current.binds.push({
        keys: keysOf(b[1]),
        title: t ? t[2].replace(/\\"/g, "\"") : humanize(action)
      });
    }
    sections = result.filter(s => s.binds.length > 0);
  }

  FileView {
    path: Quickshell.env("HOME") + "/.config/niri/modules/binds.kdl"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parse(text())
  }
}
