# 5. Motion

[PHILOSOPHY](../PHILOSOPHY.md) says motion is part of the design: animations should explain what just happened. This chapter builds the one piece most of yurice's motion runs on, a ~60-line damped spring, and then the three small components that use it to show, hide and switch things.

## Why not just `NumberAnimation`?

QtQuick's standard animation goes from A to B in a fixed duration, along an easing curve. It's perfect for a hover fade. It falls apart in two common situations:

1. **Interruptions.** You click an island and it starts growing into a panel. Halfway through, you move the mouse away and it should shrink back. A duration animation either finishes first (feels laggy) or restarts from the current value with zero speed (feels like hitting a wall).
2. **Matching the compositor.** niri animates windows with springs. When a window slides and a panel opens at the same moment, a cubic curve next to a spring looks like two programs. It _is_ two programs, but I want it look **consistent.**

A **spring** solves both. It doesn't have a duration, it has _physics_: a target it's pulled toward, and a velocity it keeps. Change the target mid-flight and it simply curves toward the new one, carrying its momentum.

## The physics, briefly

Picture a weight on a spring, sliding through honey:

- The spring pulls the weight toward the **target** with a force proportional to the distance: `-k · x`, where `k` is the **stiffness** and `x` is the distance from the target.
- The honey pushes back proportional to the speed: `-c · v`, where `c` is the **damping**.

Each moment, the acceleration is `-k·x - c·v`. Add it to the velocity, add the velocity to the position, and repeat. That's the entire simulation.

The useful knob isn't `c` itself but the **damping ratio**:

- **< 1:** it overshoots and wobbles.
- **= 1:** "critically damped". It arrives as fast as possible without overshooting.
- **> 1:** sluggish.

yurice uses 1.0, with stiffness 800, the same values niri uses for its own movement springs.

## Step 1: a spring you can see

Simplified first version:

```qml
Item {
  property real target: 0
  property real value: 0
  property real velocity: 0

  FrameAnimation {
    running: true
    onTriggered: {
      const k = 800, c = 2 * Math.sqrt(k);
      const x = value - target;
      velocity += (-k * x - c * velocity) * frameTime;
      value += velocity * frameTime;
    }
  }
}
```

`FrameAnimation` fires once per frame, with `frameTime` in seconds. Bind something's `x` to `value`, change `target`, and it glides there.

It has three problems:

1. It runs forever, burning CPU even when it's settled.
2. One big step per frame is unstable. On a slow frame (`frameTime` = 0.1s) a stiff spring overshoots wildly and can blow up to infinity.
3. It ignores niri's global animation speed.

## Step 2: the real Spring

Here's the full [`components/Spring.qml`](../../config/quickshell/components/Spring.qml):

```qml
Item {
  id: root

  property real target: 0
  property real value: 0
  property real velocity: 0
  property real stiffness: Theme.springStiffness
  property real dampingRatio: Theme.springDamping
  property real epsilon: Theme.springEpsilon
  property real slowdown: Theme.animSlowdown
  readonly property bool running: frames.running
  readonly property real progress: Math.max(0, Math.min(1, value))

  signal settled

  function snap() {
    frames.stop();
    velocity = 0;
    value = target;
  }

  function jump(to) {
    frames.stop();
    velocity = 0;
    value = to;
    target = to;
  }

  onTargetChanged: {
    if (target !== value || velocity !== 0)
      frames.start();
  }

  FrameAnimation {
    id: frames

    onTriggered: {
      const k = root.stiffness;
      const c = 2 * root.dampingRatio * Math.sqrt(k);
      let dt = Math.min(frameTime, 0.05) / root.slowdown;
      let x = root.value - root.target;
      let v = root.velocity;
      while (dt > 0) {
        const h = Math.min(0.001, dt);
        v += (-k * x - c * v) * h;
        x += v * h;
        dt -= h;
      }
      if (Math.abs(x) < root.epsilon && Math.abs(v) < root.epsilon) {
        stop();
        root.velocity = 0;
        root.value = root.target;
        root.settled();
      } else {
        root.velocity = v;
        root.value = root.target + x;
      }
    }
  }
}
```

Each problem from step 1 has its fix:

- **It only runs while moving.** `onTargetChanged` starts the frame loop. When both distance and speed drop below `epsilon`, it stops, lands exactly on the target, and fires `settled`. A settled spring costs nothing.
- **It's stable.** The frame time is capped at 50 ms, and then split into **1 ms sub-steps** (`while (dt > 0)`). A slow frame does more small steps instead of one huge one, so even a stiff spring can't explode. The sub-step update is _semi-implicit Euler_: velocity first, then position using the new velocity. It's simple, and stable for springs.
- **It respects niri's speed.** `dt` is divided by `slowdown`. niri's config has `animations { slowdown 1.7 }`, and `Theme.animSlowdown` is the same 1.7. Change one, change the other, and the shell and the compositor keep moving at the same pace.

There are also two escape hatches:

- **`snap()`** jumps straight to the current target. Most users call it from `Component.onCompleted`, so things _start_ in the right place instead of animating in when the shell loads.
- **`jump(to)`** sets both value and target at once, with no animation. The slider uses it while you drag (step 4).

`progress` is `value` clamped to 0–1. Many springs here go from 0 to 1, and `progress` is the safe version to drive opacity with, which must never go negative even if the spring overshoots slightly.

## Step 3: Reveal and Collapse

The most common animated thing in a bar is _something appearing next to something else_. When you hover the clock, the date slides out beside it. [`components/Reveal.qml`](../../config/quickshell/components/Reveal.qml) does this for widths:

```qml
Item {
  id: root

  property bool shown: false
  property real leading: Theme.pillIconGap
  default property alias content: holder.data

  implicitWidth: (holder.childrenRect.width + leading) * spring.value
  implicitHeight: Theme.pillHeight
  clip: true
  visible: spring.value > 0.001

  Spring {
    id: spring
    target: root.shown ? 1 : 0
    Component.onCompleted: snap()
  }

  Item {
    id: holder
    x: root.leading
    anchors.verticalCenter: parent.verticalCenter
    width: childrenRect.width
    height: childrenRect.height
    opacity: spring.progress
  }
}
```

Three ideas:

- **`default property alias content: holder.data`.** Whatever you nest inside a `Reveal { … }` actually goes into `holder`. Callers write natural QML. This is the standard QML way to make a "container" component.
- **Width is the content's width times the spring.** The children never squash, because they're clipped. The _window onto them_ gets wider, so it looks like the content slides out from behind its neighbour.
- **`visible: spring.value > 0.001`.** A fully hidden reveal is invisible, so it costs nothing to draw.

Here's how the clock uses it:

```qml
  Reveal {
    shown: root.expanded
    leading: Theme.pillSegmentGap

    Text {
      text: Qt.formatDateTime(Clock.date, "ddd dd MMM")
      ...
    }
  }
```

[`modules/bar/TimeIsland.qml:47-57`](../../config/quickshell/modules/bar/TimeIsland.qml#L47-L57)

[`components/Collapse.qml`](../../config/quickshell/components/Collapse.qml) is the same idea turned 90 degrees, for heights inside panels. It adds one touch: the content also slides 12 pixels down as it appears (`y: root.leading + (root.progress - 1) * 12`), so new rows drop into place instead of being uncovered.

## Step 4: springs in ordinary components

Once a spring exists, small components start using it.

**Slider.** The value can change from outside, for example when you press a volume key. The handle should glide there, but while _you_ drag it, it must follow your finger exactly:

```qml
  onValueChanged: pressed ? spring.jump(value) : spring.target = value
```

[`components/Slider.qml:36`](../../config/quickshell/components/Slider.qml#L36)

This is the reason `jump()` exists.

**Bar hiding.** When a window covers the whole screen, the bar slides up out of the way:

```qml
  readonly property real hideOffset: -(Theme.barMarginTop + Theme.barHeight + 8) * hide.value
  ...
  Spring {
    id: hide
    target: root.covered ? 1 : 0
  }
```

[`modules/bar/Bar.qml:20-29`](../../config/quickshell/modules/bar/Bar.qml#L20-L29)

That's two lines of logic. The binding from chapter 2 flips `covered`, the spring turns it into motion, and the offset follows.

Notice the shape that keeps repeating: **a boolean becomes a 0→1 spring, and every animated property is a formula of that one number.** It keeps motion coordinated. Width, opacity and offset can't drift apart, because they're the same number.

## Step 5: TabTransition, when a spring isn't right

Not everything should be a spring. Switching tabs inside a panel is a _sequence_: the old content fades out and slides away, the content is swapped, then the new content slides in. And the slide direction depends on whether the new tab is to the left or the right.

[`components/TabTransition.qml`](../../config/quickshell/components/TabTransition.qml) is an invisible object that just produces three numbers, `shown`, `fade` and `slide`, for the panel to bind to:

```qml
  onCurrentChanged: {
    if (shown === "")
      return;
    direction = order.indexOf(current) >= order.indexOf(shown) ? 1 : -1;
    anim.restart();
  }

  SequentialAnimation {
    id: anim

    ParallelAnimation {
      NumberAnimation { target: root; property: "fade"; to: 0; duration: Theme.animPress; easing.type: Easing.InQuad }
      NumberAnimation { target: root; property: "slide"; to: -root.direction * Theme.slideDistance / 2; ... }
    }
    ScriptAction {
      script: {
        root.shown = root.current;
        root.slide = root.direction * Theme.slideDistance;
      }
    }
    ParallelAnimation {
      NumberAnimation { target: root; property: "fade"; to: 1; duration: Theme.animMove; easing.type: Easing.OutQuad }
      NumberAnimation { target: root; property: "slide"; to: 0; duration: Theme.animSlide; easing.type: Theme.easeOut }
    }
  }
```

[`components/TabTransition.qml:19-67`](../../config/quickshell/components/TabTransition.qml#L19-L67), slightly compacted

The panel stays in charge of _what_ is shown. The transition only tells it _when_ to swap, and how to offset and fade. Here's the wallpaper panel switching between its library and search tabs:

```qml
  TabTransition {
    id: transition
    current: root.tab
    order: ["library", "search"]
  }
  ...
  Loader {
    id: content
    ...
    opacity: transition.fade
    transform: Translate {
      x: transition.slide
    }
    active: transition.shown !== ""
    sourceComponent: transition.shown === "search" ? searchTab : libraryTab
  }
```

[`modules/bar/WallpaperPanel.qml`](../../config/quickshell/modules/bar/WallpaperPanel.qml)

Because every tabbed panel uses this one component, they all switch the same way.

## Choosing the tool

| Situation                                         | Use                                                                             |
| ------------------------------------------------- | ------------------------------------------------------------------------------- |
| Something moves, grows, or can be interrupted     | `Spring`, or `Reveal` / `Collapse`                                              |
| A short color or opacity change on hover or press | `Behavior` + `NumberAnimation` / `ColorAnimation` with a `Theme.anim*` duration |
| A fixed multi-step sequence                       | `SequentialAnimation`, as in `TabTransition`                                    |

## Recap

- `Spring` is a critically damped spring simulation in fixed 1 ms sub-steps. It runs only while moving, slows down with niri's `slowdown`, and handles interruptions naturally.
- A boolean becomes a 0→1 spring, and all animated properties derive from it.
- `Reveal` and `Collapse` show and hide content by springing the clip size.
- `TabTransition` sequences tab switches the same way everywhere.

We now have text, icons, images and motion. The last foundation is the set of bigger building blocks every panel is made of.
