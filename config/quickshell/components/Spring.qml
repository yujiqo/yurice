pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

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
