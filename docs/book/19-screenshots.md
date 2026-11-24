# 19. Screenshots

`Print` freezes the screen, dims it, and lets you drag out a region. `Ctrl+C` copies it, `Ctrl+S` saves it, `Ctrl+Shift+S` saves the whole screen, `P` toggles the mouse pointer, and `Esc` cancels. There's no separate screenshot program involved. The whole tool is [`services/Screenshot.qml`](../../config/quickshell/services/Screenshot.qml) and one overlay window per screen, [`modules/screenshot/ScreenshotOverlay.qml`](../../config/quickshell/modules/screenshot/ScreenshotOverlay.qml).

## Freezing the screen

The trick to a screenshot tool that feels instant is to capture first and select second. What you select from is a still image of the moment you pressed `Print`, so a tooltip or a video frame can't change under you while you drag.

quickshell has a type for that, `ScreencopyView`, which shows a capture of a screen using Wayland's screencopy protocol. With `live: false` it captures once and keeps the frame. The overlay captures each screen twice, with and without the pointer:

```qml
        ScreencopyView {
          id: plain
          anchors.fill: parent
          z: Screenshot.showPointer ? 0 : 1
          captureSource: root.modelData
          live: false
          paintCursor: false
          onHasContentChanged: if (hasContent && pointer.hasContent)
            Screenshot.markReady(root.name)
        }

        ScreencopyView {
          id: pointer
          anchors.fill: parent
          z: Screenshot.showPointer ? 1 : 0
          captureSource: root.modelData
          live: false
          paintCursor: true
          onHasContentChanged: if (hasContent && plain.hasContent)
            Screenshot.markReady(root.name)
        }
```

[`modules/screenshot/ScreenshotOverlay.qml:109-129`](../../config/quickshell/modules/screenshot/ScreenshotOverlay.qml#L109-L129)

Pressing `P` only swaps which one is on top. Both were taken at the same moment, so showing or hiding the pointer later is free and exact.

## The phases

The service moves through a few phases, like the lock screen will in the next chapter:

```qml
  function start() {
    if (phase !== "")
      return;
    output = Niri.activeOutput;
    takenAt = new Date();
    ...
    phase = "capturing";
    fallback.restart();
  }
```

[`services/Screenshot.qml:30-42`](../../config/quickshell/services/Screenshot.qml#L30-L42)

In `capturing`, every overlay loads its two captures. Each screen reports `markReady` when both have content, and when all screens have, the phase becomes `selecting`. The overlays then dim, take keyboard focus on the screen you're using, and start accepting the mouse. A 1.5 second fallback moves on even if a capture never arrives, so a misbehaving monitor can't leave you stuck.

`takenAt` is recorded at the start, so the file name has the time you pressed `Print`, not the time you finished selecting.

The overlay windows exist all the time, one per screen from `shell.qml`. Only their contents are loaded on demand, and their input mask is empty unless a screenshot is in progress, so they cost nothing and block nothing the rest of the time.

## Selecting

Over the frozen frame sits a 45% scrim. The selection has to look undimmed, so it's drawn again on top of the scrim with a `ShaderEffectSource`, a live view of part of another item:

```qml
      ShaderEffectSource {
        id: region
        x: Screenshot.selX
        y: Screenshot.selY
        width: Math.max(1, Screenshot.selW)
        height: Math.max(1, Screenshot.selH)
        visible: root.hasSel
        sourceItem: root.view
        sourceRect: Qt.rect(x, y, width, height)
        ...
      }
```

[`modules/screenshot/ScreenshotOverlay.qml:157-169`](../../config/quickshell/modules/screenshot/ScreenshotOverlay.qml#L157-L169)

`sourceItem` is whichever capture is showing, and `sourceRect` is the same rectangle as the selection, so the region shows exactly the pixels under it at full brightness. That same item is what gets saved, which is the next section.

A full-screen `MouseArea` handles the mouse. Dragging on empty space draws a new region. Once there is one, `hitTest` checks whether the pointer is within 12 pixels of an edge or corner, or inside the region, and the cursor shape changes to match. Dragging an edge resizes, dragging a corner resizes two edges, and dragging inside moves the whole region.

Selections snap to physical pixels:

```qml
  function select(left, top, right, bottom) {
    const scale = scaleOf(view);
    const l = Math.round(Math.min(left, right) * scale) / scale;
    const t = Math.round(Math.min(top, bottom) * scale) / scale;
    const r = Math.round(Math.max(left, right) * scale) / scale;
    const b = Math.round(Math.max(top, bottom) * scale) / scale;
    Screenshot.setSelection(name, l, t, r - l, b - t);
  }
```

[`modules/screenshot/ScreenshotOverlay.qml:49-56`](../../config/quickshell/modules/screenshot/ScreenshotOverlay.qml#L49-L56)

On a screen with 1.5× scaling, one logical pixel is 1.5 real ones. Without rounding, a selection edge could fall in the middle of a real pixel and the saved image would have a blurry half-pixel border. Rounding in physical pixels and converting back keeps every edge on the pixel grid.

## The panel

While you select, the center island on the bar shows the screenshot panel, a two-column list of the shortcuts. It's not the bar's island, though. The bar is under the overlay. The overlay draws its own copy of `Workspaces` in the same place, with its `current` set to `"screenshot"`:

```qml
      Workspaces {
        id: hint
        output: root.name
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Theme.barMarginTop
        current: root.selecting ? "screenshot" : ""
        onDismissed: Screenshot.cancel()
        onProgressChanged: if (Screenshot.closing && progress < 0.01)
          Screenshot.closed()
      }
```

[`modules/screenshot/ScreenshotOverlay.qml:341-351`](../../config/quickshell/modules/screenshot/ScreenshotOverlay.qml#L341-L351)

Since an island only follows `current` (chapter 11), setting it directly opens the panel without any bar involved. It looks exactly like the bar's island growing, because it is the same component in the same spot. When you cancel, the phase becomes `closing`, the island shrinks, and only when its `progress` reaches zero does the overlay go away. The region hints are dimmed until there's a region to act on.

## Saving

Saving uses `grabToImage`, which renders an item into an image:

```qml
  function grabRegion(callback) {
    const scale = scaleOf(view);
    region.grabToImage(callback, Qt.size(Math.round(region.width * scale), Math.round(region.height * scale)));
  }
```

[`modules/screenshot/ScreenshotOverlay.qml:58-61`](../../config/quickshell/modules/screenshot/ScreenshotOverlay.qml#L58-L61)

It grabs the `ShaderEffectSource`, the same item showing the selection, at the capture's physical resolution, so a region on a HiDPI screen is saved at full detail. The full-screen save grabs the capture itself.

The service then writes the result:

- `Ctrl+S` saves to `~/Pictures/Screenshots/Screenshot from 2026-11-24 14-03-12.png`, or the folder you chose in settings.
- `Ctrl+Shift+S` saves the whole screen you're on (or the one with the selection) to the same folder.
- `Ctrl+C` saves to `~/.cache/yurice/screenshot.png` and pipes it to `wl-copy --type image/png`.

Each one ends with a toast (chapter 18): "Region saved" with the path, "Copied to clipboard" with the size, or "Screenshot failed". Because the clipboard history watches images too, a copied screenshot also shows up in `Mod+Y`.

The last chapter of Part IV is about the screen that comes before all of this, and the one that covers it when you step away.
