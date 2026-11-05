pragma Singleton
import Quickshell
import QtQuick

Singleton {
  // --- Accent palette ---
  readonly property color clock: "#f5c26b"
  readonly property color music: "#f78fb3"
  readonly property color wifi: "#6bb8ff"
  readonly property color ethernet: "#a0a8a8"
  readonly property color bluetooth: "#4d8eff"
  readonly property color off: "#5c6664"
  readonly property color volume: "#c792ea"
  readonly property color brightness: "#ffcb6b"
  readonly property color good: "#7bd88f"
  readonly property color charging: "#f9e26b"
  readonly property color warn: "#ff9e64"
  readonly property color bad: "#ff6b6b"
  readonly property color balanced: "#7fd1c7"

  // --- Surfaces / text ---
  readonly property color surface: "#040e0d"
  readonly property color surfaceHover: "#0d1f1d"
  readonly property color divider: "#3a4a48"
  readonly property color text: "#f5e2c5"

  // --- Workspace dots ---
  readonly property color wsActive: bad
  readonly property color wsUrgent: warn
  readonly property color wsOccupied: "#8a7d6b"
  readonly property color wsEmpty: "#2a3634"

  // --- Metrics ---
  readonly property int barHeight: 30
  readonly property int barMarginTop: 10
  readonly property int barMargin: 10
  readonly property int barGap: 5
  readonly property int pillHeight: 30
  readonly property int pillPadding: 10
  readonly property int pillSegmentGap: 8
  readonly property int pillIconGap: 5
  readonly property int wsDot: 12
  readonly property int wsDotActive: 28
  readonly property int wsGap: 6

  // --- Fonts ---
  readonly property string iconFont: "Material Symbols Sharp"
  readonly property int iconSize: 16
  readonly property string labelFont: "Agave Nerd Font"
  readonly property int labelSize: 18

  // --- Animation ---
  readonly property int animPress: 100
  readonly property int animHover: 120
  readonly property int animResize: 150
  readonly property int animColor: 200
  readonly property int animRemove: 200
  readonly property int animMove: 250
  readonly property int easeOut: Easing.OutCubic
}
