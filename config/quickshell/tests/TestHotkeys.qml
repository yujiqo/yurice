import QtQuick
import qs.services

QtObject {
  function test_keysOf(t) {
    t.eq(Hotkeys.keysOf("Mod+Shift+Slash"), ["Super", "Shift", "/"]);
    t.eq(Hotkeys.keysOf("XF86AudioMute"), ["Mute"]);
    t.eq(Hotkeys.keysOf("XF86Calculator"), ["Calculator"]);
  }

  function test_humanize(t) {
    t.eq(Hotkeys.humanize("focus-column-left;"), "Focus column left");
    t.eq(Hotkeys.humanize('spawn "kitty" "--single"'), "Spawn kitty --single");
  }

  function test_parse(t) {
    Hotkeys.parse(['binds {', '  Mod+T { spawn "kitty"; }', '  // section: Windows', '  Mod+Q repeat=false hotkey-overlay-title="Close \\"it\\"" { close-window; }', '  // Mod+X { quit; }', '  Mod+Shift+Slash { show-hotkey-overlay; }', '  Mod+H hotkey-overlay-title=null { focus-column-left; }', '  // section: Empty', '}'].join("\n"));
    t.eq(Hotkeys.sections, [{
        title: "General",
        binds: [{
            keys: ["Super", "T"],
            title: "Spawn kitty"
          }]
      }, {
        title: "Windows",
        binds: [{
            keys: ["Super", "Q"],
            title: 'Close "it"'
          }]
      }]);
  }
}
