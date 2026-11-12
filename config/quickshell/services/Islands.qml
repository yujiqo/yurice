pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

Singleton {
  id: root

  readonly property var list: [
    {
      id: "media",
      icon: "music_note",
      label: "Media",
      panels: ["media"]
    },
    {
      id: "theme",
      icon: "contrast",
      label: "Theme",
      panels: ["theme"]
    },
    {
      id: "wallpapers",
      icon: "wallpaper_slideshow",
      label: "Wallpapers",
      panels: ["wallpapers"]
    },
    {
      id: "danbooru",
      icon: "palette",
      label: "Danbooru",
      panels: ["danbooru"]
    },
    {
      id: "weeb",
      icon: "visibility",
      label: `${WeebMode.primaryLabel} / ${WeebMode.secondaryLabel} mode`,
      panels: ["weeb"]
    },
    {
      id: "weather",
      icon: "partly_cloudy_day",
      label: "Weather",
      panels: ["weather"]
    },
    {
      id: "connectivity",
      icon: "wifi",
      label: "Wi-Fi and Bluetooth",
      panels: ["wifi", "bluetooth"]
    },
    {
      id: "levels",
      icon: "volume_up",
      label: "Volume and brightness",
      panels: ["volume", "brightness"]
    },
    {
      id: "battery",
      icon: "battery_android_full",
      label: "Battery",
      panels: ["battery"]
    },
    {
      id: "time",
      icon: "schedule",
      label: "Clock",
      panels: ["calendar"]
    }
  ]

  readonly property bool ready: WeebMode.loaded
  readonly property var hidden: list.map(island => island.id).filter(id => !shown(id))

  function enabled(id) {
    return !Settings.hiddenIslands.includes(id);
  }

  function shown(id) {
    if (!enabled(id))
      return false;
    if (WeebMode.hidesIsland(id))
      return false;
    if (id === "media")
      return Media.active !== null;
    if (id === "battery")
      return Battery.available;
    return true;
  }

  function setEnabled(id, on) {
    const rest = Settings.hiddenIslands.filter(other => other !== id);
    Settings.set("hiddenIslands", on ? (rest.length > 0 ? rest : undefined) : rest.concat([id]));
  }

  function owner(panel) {
    return list.find(island => island.panels.includes(panel))?.id ?? "";
  }

  function panelShown(panel) {
    const id = owner(panel);
    return id === "" || !hidden.includes(id);
  }
}
