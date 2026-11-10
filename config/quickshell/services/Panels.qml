pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property var names: ["user", "media", "wallpapers", "danbooru", "theme", "weeb", "weather", "wifi", "bluetooth", "volume", "brightness", "battery", "calendar", "hotkeys"]

  property string name: ""
  property string output: ""
  readonly property bool keyboard: name !== ""

  function open(next) {
    if (!names.includes(next) || (next === "danbooru" && WeebMode.hidesDanbooru))
      return;
    output = Niri.focusedOutput || (Quickshell.screens[0]?.name ?? "");
    name = next;
  }

  function close() {
    name = "";
  }

  function toggle(next) {
    if (name === next)
      close();
    else
      open(next);
  }

  IpcHandler {
    target: "panel"

    function toggle(name: string): void {
      root.toggle(name);
    }
    function open(name: string): void {
      root.open(name);
    }
    function close(): void {
      root.close();
    }
  }
}
