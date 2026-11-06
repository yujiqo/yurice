pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string paletteFile: Quickshell.env("HOME") + "/.cache/yurice/colors.json"

  function reloadPalette() {
    paletteView.reload();
  }

  // --- Accent palette ---
  readonly property color clock: palette.clock || "#f5c26b"
  readonly property color music: palette.music || "#f78fb3"
  readonly property color wifi: palette.wifi || "#6bb8ff"
  readonly property color ethernet: palette.ethernet || "#a0a8a8"
  readonly property color bluetooth: palette.bluetooth || "#4d8eff"
  readonly property color off: palette.outline || "#5c6664"
  readonly property color volume: palette.volume || "#c792ea"
  readonly property color brightness: palette.brightness || "#ffcb6b"
  readonly property color good: palette.good || "#7bd88f"
  readonly property color charging: palette.charging || "#f9e26b"
  readonly property color warn: palette.warn || "#ff9e64"
  readonly property color bad: palette.bad || "#ff6b6b"
  readonly property color balanced: palette.balanced || "#7fd1c7"

  // --- Surfaces / text ---
  readonly property color surface: palette.surface || "#040e0d"
  readonly property color surfaceHover: palette.surfaceContainerHigh || "#0d1f1d"
  readonly property color divider: palette.outlineVariant || "#3a4a48"
  readonly property color text: palette.onSurface || "#f5e2c5"

  // --- Workspace dots ---
  readonly property color wsActive: bad
  readonly property color wsUrgent: warn
  readonly property color wsOccupied: palette.outline || "#8a7d6b"
  readonly property color wsEmpty: palette.surfaceContainerHighest || "#2a3634"

  FileView {
    id: paletteView
    path: root.paletteFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()

    JsonAdapter {
      id: palette
      property string clock
      property string music
      property string wifi
      property string ethernet
      property string bluetooth
      property string volume
      property string brightness
      property string good
      property string charging
      property string warn
      property string bad
      property string balanced
      property string surface
      property string surfaceContainer
      property string surfaceContainerHigh
      property string surfaceContainerHighest
      property string onSurface
      property string outline
      property string outlineVariant
    }
  }

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
  readonly property real pickerScale: 0.3
  readonly property int pickerGap: 24
  readonly property int pickerRadius: 14
  readonly property int pickerBorder: 3

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
  readonly property int animWallpaper: 800
  readonly property int animPickerFade: 200
  readonly property real animSlowdown: 1.7
  readonly property real springStiffness: 800
  readonly property real springDamping: 1.0
  readonly property real springEpsilon: 0.0001
  readonly property real pickerStagger: 0.06
  readonly property real pickerRevealWidth: 0.35
  readonly property real pickerFadeOutAt: 0.03
  readonly property real pickerThumbOversample: 1.0
  readonly property real pickerBlurMax: 48
  readonly property real pickerBlurScale: 0.25
  readonly property real pickerDim: 0.45
  readonly property int easeOut: Easing.OutCubic
}
