import QtQuick
import qs.components

Item {
  id: suite

  property bool shown: true

  Spring {
    id: bound
    target: suite.shown ? 1 : 0
  }

  Spring {
    id: free
  }

  function test_snapKeepsBinding(t) {
    bound.snap();
    t.eq([bound.value, bound.velocity, bound.running], [1, 0, false]);
    suite.shown = false;
    t.eq(bound.target, 0, "target binding survives snap()");
    t.ok(bound.running, "a target change starts the animation");
    bound.snap();
    t.eq(bound.value, 0);
    suite.shown = true;
    bound.snap();
  }

  function test_jumpSetsTarget(t) {
    free.jump(0.5);
    t.eq([free.value, free.target, free.velocity, free.running], [0.5, 0.5, 0, false]);
  }

  function test_progressIsClamped(t) {
    free.jump(1.4);
    t.eq(free.progress, 1);
    free.jump(-0.3);
    t.eq(free.progress, 0);
    free.jump(0.25);
    t.eq(free.progress, 0.25);
  }
}
