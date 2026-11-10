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

  function formatDuration(seconds) {
    const total = Math.max(0, Math.round(seconds / 60));
    const days = Math.floor(total / 1440);
    const hours = Math.floor(total % 1440 / 60);
    const minutes = total % 60;
    if (days > 0)
      return `${days}d ${hours}h ${minutes}m`;
    if (hours > 0)
      return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  }
}
