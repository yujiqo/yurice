# 4. Primitives

Before we can build a bar, we need text, icons and pictures that look right. QtQuick has `Text`, `Image` and `Rectangle`, but used raw they take the same five lines of setup every time, and those five lines slowly drift apart between files. This chapter wraps each one _once_, in [`components/`](../../config/quickshell/components), so every later file gets them right for free.

The pattern is the same every time:

1. Take a QtQuick type.
2. Set the theme-related properties.
3. Expose only the few knobs callers actually need.

## Icon

yurice draws icons with a **font**: Google's Material Symbols. An icon is just a `Text` whose text is the icon's name, like `"wifi"` or `"battery_full"`. The font turns the name into a glyph through a feature called ligatures.

Here's the whole component:

```qml
Text {
  property real size: Theme.iconSize
  property real fill: 0
  property real weight: 400

  font.family: Theme.iconFont
  font.pixelSize: size
  font.variableAxes: ({
      "opsz": Math.max(20, Math.min(48, size)),
      "wght": weight,
      "FILL": fill,
      "GRAD": 0
    })
  renderType: Text.CurveRendering
}
```

[`components/Icon.qml`](../../config/quickshell/components/Icon.qml)

Why bother:

- **Material Symbols is a variable font.** `FILL` goes smoothly from outlined (0) to filled (1), and `wght` sets the stroke weight. Since these are properties, they can be animated. An icon can _fill in_ when its toggle turns on.
- **`opsz` (optical size)** tells the font which size it's being drawn at, so small icons get slightly thicker strokes and stay readable.
- **`Text.CurveRendering`** draws glyphs as vector curves instead of cached bitmaps, so icons stay crisp while they're scaled in an animation. There's a whole commit about it: "rework icon rendering to render them as vector graphics".

Usage: `Icon { text: "wifi"; color: Theme.wifi; fill: 1 }`. The full icon list is at [fonts.google.com/icons](https://fonts.google.com/icons).

## Label

Text needs a bit more care. The obvious `Text { font.family: Theme.labelFont }` has two problems in a bar:

1. **Vertical alignment drifts.** A `Text`'s height depends on the font's line height, which varies. Centering two labels with different sizes puts their baselines at different heights.
2. **Changing text makes things jump.** When the clock goes from `9:59` to `10:00`, the label gets wider in one frame, and everything next to it jumps.

[`components/Label.qml`](../../config/quickshell/components/Label.qml) solves both:

```qml
Item {
  id: root

  property alias text: label.text
  property alias color: label.color
  property real maxWidth: Infinity
  property int pixelSize: Theme.labelSize
  property bool smooth: false

  implicitWidth: Math.min(smooth ? widthSpring.value : label.implicitWidth, maxWidth)
  implicitHeight: metrics.height
  ...
  FontMetrics {
    id: metrics
    font: label.font
  }

  Text {
    id: label
    width: root.smooth ? implicitWidth : root.width
    anchors.baseline: parent.top
    anchors.baselineOffset: metrics.ascent
    elide: root.smooth ? Text.ElideNone : Text.ElideRight
    ...
  }
}
```

- **The baseline is pinned.** `FontMetrics` gives the font's exact ascent, and the text's baseline is anchored at that distance from the top. Any two `Label`s with the same `pixelSize` line up perfectly.
- **`smooth: true`** makes the width follow a spring instead of jumping, and fades new text in. This is how the clock changes format without a jolt (the "make clock format change smooth" commit). We build `Spring` in the next chapter.
- **`maxWidth` plus `ElideRight`** gives long text an ellipsis instead of overflowing.

## HoverHighlight

Lots of things in the bar react to hover with the same soft pill behind them. Instead of copying that, there's one component:

```qml
Rectangle {
  property bool active: false

  height: Theme.pillHeight - 6
  radius: height / 2
  color: Theme.surfaceContainerHigh
  opacity: active ? 1 : 0
  scale: active ? 1 : 0.9

  Behavior on opacity {
    NumberAnimation {
      duration: Theme.animHover
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: Theme.animMove
      easing.type: Easing.OutBack
    }
  }
}
```

[`components/HoverHighlight.qml`](../../config/quickshell/components/HoverHighlight.qml)

It fades in **and** grows from 90% with a slight overshoot (`OutBack`). It's a tiny detail, and it makes hovering feel physical rather than like a color switch. Everything that wants a hover pill uses this, so they all feel identical.

## FocusRing

The keyboard twin of the hover highlight. Drop it inside anything focusable and it draws a ring while that thing has keyboard focus:

```qml
Rectangle {
  property Item target: parent

  anchors.fill: parent
  z: 100
  opacity: target.activeFocus ? 1 : 0
  visible: opacity > 0
  color: "transparent"
  radius: parent.radius ?? height / 2
  border.width: 2
  border.color: Theme.text
  ...
}
```

[`components/FocusRing.qml`](../../config/quickshell/components/FocusRing.qml)

- `radius: parent.radius ?? height / 2` copies the parent's corner radius, so the ring fits buttons, cards and pills alike.
- Using the ring is one line: `FocusRing {}`. Every interactive component in the next chapters has one. That's a big part of how "everything works by keyboard" stays true as the shell grows.

Why mouse users never see it is a question of _when_ things get focus, not of the ring itself. Chapter 12 covers that.

## Divider

The thin vertical line between parts of an island. It's a primitive, but it already animates. When `shown` changes, the gap around it widens and the line grows from nothing:

```qml
  implicitWidth: Theme.pillSegmentGap * (1 + progress) + progress
  ...
  Rectangle {
    anchors.centerIn: parent
    width: 1
    height: 14 * root.progress
    ...
    opacity: root.progress
  }
```

[`components/Divider.qml`](../../config/quickshell/components/Divider.qml)

`progress` comes from a spring going from 0 to 1. Keep this pattern in mind: **one number from 0 to 1, with several properties derived from it.** It's the core of chapter 5.

## RoundedImage: our first shader

Avatars, wallpaper thumbnails and album covers all need rounded corners. QtQuick's `Image` can't clip to a rounded rectangle. The usual workarounds (masks, `layer.effect`) cost an extra offscreen pass for every image. With dozens of thumbnails in a grid, that adds up on a laptop GPU.

yurice instead writes a tiny **fragment shader**: a program that runs on the GPU once per pixel and decides that pixel's color. Here it is in full:

```glsl
void main() {
    vec2 halfSize = size * 0.5;
    vec2 q = abs(qt_TexCoord0 * size - halfSize) - (halfSize - vec2(radius));
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
    float aa = max(fwidth(d), 1e-4);
    float coverage = clamp(0.5 - d / aa, 0.0, 1.0);
    vec4 color = texture(source, uvRect.xy + qt_TexCoord0 * uvRect.zw);
    fragColor = color * coverage * qt_Opacity;
}
```

[`shaders/roundedimage.frag`](../../config/quickshell/shaders/roundedimage.frag)

Reading it line by line:

1. **Work out how far the pixel is from the rounded-rectangle edge.** This is called a _signed distance_. `d` is negative inside the shape, zero on the edge and positive outside. The two lines that compute `q` and `d` are the standard rounded-box distance formula.
2. **Turn distance into coverage, with anti-aliasing.** `fwidth(d)` is how much `d` changes from one pixel to the next. Dividing by it makes the edge exactly one pixel soft at any size, so it's smooth and never blurry.
3. **Sample the image, cropped.** `uvRect` says which part of the image to use. More on that below.
4. **Multiply the color by coverage**, so pixels outside the corners become transparent.

On the QML side, [`RoundedImage.qml`](../../config/quickshell/components/RoundedImage.qml) hides a normal `Image` (`visible: false`) and draws it through a `ShaderEffect`. A `ShaderEffect` passes its own properties to the shader by name: `source`, `size`, `radius`, `uvRect`.

```qml
  ShaderEffect {
    property Image source: image
    property size size: Qt.size(width, height)
    property real radius: Math.min(root.radius, Math.min(width, height) / 2)
    property vector4d uvRect: {
      const iw = image.implicitWidth;
      const ih = image.implicitHeight;
      if (iw <= 0 || ih <= 0 || width <= 0 || height <= 0)
        return Qt.vector4d(0, 0, 1, 1);
      const boxAspect = width / height;
      const imageAspect = iw / ih;
      if (imageAspect > boxAspect) {
        const sx = boxAspect / imageAspect;
        return Qt.vector4d((1 - sx) / 2, 0, sx, 1);
      }
      const sy = imageAspect / boxAspect;
      return Qt.vector4d(0, (1 - sy) / 2, 1, sy);
    }
    ...
    fragmentShader: Qt.resolvedUrl("../shaders/roundedimage.frag.qsb")
  }
```

`uvRect` re-creates "preserve aspect, crop to fill" for the shader. If the image is wider than the box, only a centered slice of its width is used. If it's taller, only a centered slice of its height.

Qt can't load `.frag` source directly. It needs a compiled `.qsb` file, which [`shaders/build.sh`](../../config/quickshell/shaders/build.sh) makes with Qt's `qsb` tool. The compiled file is committed, so you only rebuild it after editing the shader.

## Disc: putting it together

[`components/Disc.qml`](../../config/quickshell/components/Disc.qml), the spinning vinyl record in the media panel, uses nearly every primitive at once:

- `Rectangle`s with `radius: width / 2` make the circles.
- A `Repeater` draws seven faint groove rings.
- An `Icon` (`music_note`) is the placeholder while there's no album art.
- Two `RoundedImage`s show the cover, cropped to a circle.
- A `Shape` with a `ConicalGradient` makes the light glinting off the vinyl.

The one new idea is the **two covers**. When the track changes, the new art loads into the _hidden_ cover. Only once it's ready does the disc swap which one is shown:

```qml
  onArtChanged: {
    latest = shown === coverA ? coverB : coverA;
    latest.source = art;
    settle();
  }

  function settle() {
    if (art === "" || latest.status === Image.Ready || latest.status === Image.Error)
      shown = latest;
  }
```

[`components/Disc.qml:16-25`](../../config/quickshell/components/Disc.qml#L16-L25)

Without this, the disc would flash empty for a few frames on every track change while the image decodes. It's a small trick that removes a flash, which counts as a bug fix by this project's rules.

## Recap

- Every QtQuick basic gets wrapped **once** with the theme applied: `Icon`, `Label`, `HoverHighlight`, `FocusRing`, `Divider`, `RoundedImage`.
- Icons are a variable font, so they can fill and change weight smoothly.
- Labels pin their baseline and can change width smoothly.
- Rounded images use a small signed-distance shader instead of costly masks.

Several of these already mentioned a `Spring`. Time to build it.
