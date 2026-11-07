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
  readonly property color clock: tertiary
  readonly property color music: tertiary
  readonly property color wifi: primary
  readonly property color ethernet: primary
  readonly property color bluetooth: primary
  readonly property color off: outline
  readonly property color volume: secondary
  readonly property color brightness: secondary
  readonly property color good: primary
  readonly property color charging: tertiary
  readonly property color warn: error
  readonly property color bad: error
  readonly property color balanced: secondary
  readonly property color weather: primary
  readonly property color wallpaper: secondary

  // --- Surfaces / text ---
  readonly property color surface: palette.surface || "#040e0d"
  readonly property color surfaceHover: palette.surfaceContainerHigh || "#0d1f1d"
  readonly property color divider: palette.outlineVariant || "#3a4a48"
  readonly property color text: palette.onSurface || "#f5e2c5"
  readonly property color textVariant: palette.onSurfaceVariant || "#bec9c6"
  readonly property color surfaceContainer: palette.surfaceContainer || "#0a1a18"
  readonly property color surfaceContainerHigh: palette.surfaceContainerHigh || "#0d1f1d"
  readonly property color surfaceContainerHighest: palette.surfaceContainerHighest || "#2a3634"
  readonly property color outline: palette.outline || "#5c6664"

  // --- Material roles ---
  readonly property color primary: palette.primary || "#80d5cb"
  readonly property color onPrimary: palette.onPrimary || "#003733"
  readonly property color primaryContainer: palette.primaryContainer || "#00504a"
  readonly property color onPrimaryContainer: palette.onPrimaryContainer || "#9cf2e7"
  readonly property color secondary: palette.secondary || "#b1ccc7"
  readonly property color secondaryContainer: palette.secondaryContainer || "#324b48"
  readonly property color onSecondaryContainer: palette.onSecondaryContainer || "#cce8e3"
  readonly property color tertiary: palette.tertiary || "#adcae6"
  readonly property color error: palette.error || "#ffb4ab"

  // --- Workspace dots ---
  readonly property color wsActive: primary
  readonly property color wsUrgent: error
  readonly property color wsOccupied: outline
  readonly property color wsEmpty: surfaceContainerHighest

  FileView {
    id: paletteView
    path: root.paletteFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()

    JsonAdapter {
      id: palette
      property string surface
      property string surfaceContainer
      property string surfaceContainerHigh
      property string surfaceContainerHighest
      property string onSurface
      property string outline
      property string outlineVariant
      property string primary
      property string onPrimary
      property string primaryContainer
      property string onPrimaryContainer
      property string secondary
      property string secondaryContainer
      property string onSecondaryContainer
      property string tertiary
      property string onSurfaceVariant
      property string error
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
  readonly property int panelWidth: 360
  readonly property int panelRadius: 22
  readonly property int panelPadding: 10
  readonly property int dropdownMaxHeight: 520
  readonly property int menuListMaxHeight: 372
  readonly property int menuItemHeight: 54
  readonly property int menuItemRadius: 14
  readonly property int menuGap: 4
  readonly property int menuIconSize: 22
  readonly property int menuHeaderSize: 20
  readonly property int mediaPanelWidth: 340
  readonly property int searchPanelWidth: 520
  readonly property int launcherWidth: 560
  readonly property int discSize: 220
  readonly property int thumbHeight: 110
  readonly property int menuTitleSize: 17
  readonly property int menuSubtitleSize: 14
  readonly property int closeGrace: 400
  readonly property int animSlide: 300
  readonly property int slideDistance: 40

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
