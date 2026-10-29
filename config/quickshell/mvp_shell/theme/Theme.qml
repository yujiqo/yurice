pragma Singleton
import Quickshell
import QtQuick

Singleton {
  property color bg: "#1e1e2e" // bar background
  property color surface: "#313244" // pill background, inactive workspace
  property color surfaceAlt: "#45475a" // not wired up yet (future: hover/alt surface)
  property color text: "#cdd6f4" // default pill text
  property color textDim: "#a6adc8" // not wired up yet (future: secondary text)
  property color accent: "#ff6b6b" // active workspace
  property color warn: "#f38ba8" // low battery
  property color border: "#45475a" // CenterPanel border
  property color ok: "#a6e3a1"

  // --- Spacing scale ---
  property int s1: 4 // Workspace row spacing
  property int s2: 6 // bar margins
  property int s3: 8 // bar RowLayout spacing; Pill padding = s3 * 2
  property int s4: 22 // Pill height; inactive workspace width/height
  property int s5: 32 // bar height; active workspace width

  // --- Radii ---
  property int rSmall: 6 // not wired up yet
  property int rNormal: 11 // Pill / Workspace pill radius (half of s4)
  property int rLarge: 16 // CenterPanel radius

  // --- Fonts ---
  property string fontFamily: "" // empty = inherit Qt's default, matches current look
  property int fsSmall: 12 // ClockWidget date line, BatteryWidget time-left line
  property int fsNormal: 15 // Pill text size
  property int fsLarge: 18 // ClockWidget time, BatteryWidget icon

  // --- Animation (not wired up yet; for M2's PopupPanel motion) ---
  property int animFast: 100
  property int animNormal: 200
  property int animSlow: 350
  property int easeOut: Easing.OutCubic
}
