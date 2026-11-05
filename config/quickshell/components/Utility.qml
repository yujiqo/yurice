pragma Singleton
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
}
