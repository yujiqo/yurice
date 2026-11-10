pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell

Singleton {
  function seg(icon, label, color) {
    return {
      icon: icon,
      label: label,
      color: color
    };
  }

  function pick(value, steps, fallback) {
    for (const [threshold, result] of steps) {
      if (value >= threshold)
        return result;
    }
    return fallback;
  }

  function sameItems(a, b) {
    return a.length === b.length && a.every((item, i) => item === b[i]);
  }
}
