import QtQuick
import qs.services

QtObject {
  function apply() {
    Niri.handleEvent({
      WorkspacesChanged: {
        workspaces: [{
            id: 1,
            idx: 1,
            output: Niri.activeOutput,
            is_active: true,
            is_focused: true,
            is_urgent: false,
            active_window_id: null
          }, {
            id: 2,
            idx: 2,
            output: Niri.activeOutput,
            is_active: false,
            is_focused: false,
            is_urgent: true,
            active_window_id: null
          }]
      }
    });
    Notifications.notifyLocal("fixture-a", "info", "Fixture", "body");
    Notifications.notifyLocal("fixture-b", "keyboard", "Layout");
    Hotkeys.parse(['  // section: Apps', '  Mod+T hotkey-overlay-title="Terminal" { spawn "kitty"; }', '  Mod+Shift+Slash { focus-column-left; }'].join("\n"));
    Launcher.parseClips("1\thello\n2\t[[ binary data 1 KiB png 10x10 ]]");
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
          }],
        current_mode: 0,
        logical: {
          x: 0,
          y: 0,
          scale: 2,
          transform: "Normal"
        }
      }
    }));
    Weather.apply({
      current: {
        temperature_2m: 12,
        apparent_temperature: 10,
        relative_humidity_2m: 70,
        wind_speed_10m: 8,
        weather_code: 3,
        is_day: 1
      },
      daily: {
        time: ["2026-11-10", "2026-11-11"],
        weather_code: [3, 61],
        temperature_2m_max: [14, 11],
        temperature_2m_min: [6, 4],
        precipitation_probability_max: [5, 80],
        sunrise: ["2026-11-10T07:30", "2026-11-11T07:32"],
        sunset: ["2026-11-10T16:40", "2026-11-11T16:38"]
      }
    });
    const result = {
      id: "1",
      thumb: "file:///nonexistent.jpg",
      full: "file:///nonexistent.jpg",
      resolution: "1920x1080",
      ext: "jpg",
      purity: "sfw",
      category: "general"
    };
    WallSearch.results = [result];
    WallSearch.phase = "results";
    Danbooru.results = [result];
    Danbooru.phase = "results";
    Wallpapers.allWallpapers = ["/nonexistent/a.jpg", "/nonexistent/b.jpg"];
  }
}
