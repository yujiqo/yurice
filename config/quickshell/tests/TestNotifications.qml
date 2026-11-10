import QtQuick
import qs.services

QtObject {
  function clear() {
    while (Notifications.toasts.count > 0)
      Notifications.remove(Notifications.toasts.get(0).uid);
  }

  function test_notifyLocal(t) {
    clear();
    Notifications.notifyLocal("kb", "keyboard", "English");
    t.eq(Notifications.toasts.count, 1);
    const entry = Notifications.toasts.get(0);
    t.eq([entry.key, entry.symbol, entry.summary, entry.body, entry.timeout, entry.generation], ["kb", "keyboard", "English", "", 1500, 0]);
    clear();
  }

  function test_notifyLocal_replacesSameKey(t) {
    clear();
    Notifications.notifyLocal("kb", "keyboard", "English");
    const uid = Notifications.toasts.get(0).uid;
    Notifications.notifyLocal("kb", "keyboard", "Russian", "layout", 3000);
    t.eq(Notifications.toasts.count, 1);
    const entry = Notifications.toasts.get(0);
    t.eq([entry.uid, entry.summary, entry.body, entry.timeout, entry.generation], [uid, "Russian", "layout", 3000, 1]);
    clear();
  }

  function test_maxToasts(t) {
    clear();
    for (let i = 0; i < 5; i++)
      Notifications.notifyLocal("k" + i, "info", "n" + i);
    t.eq(Notifications.toasts.count, Notifications.maxToasts);
    const keys = [];
    for (let i = 0; i < Notifications.toasts.count; i++)
      keys.push(Notifications.toasts.get(i).key);
    t.eq(keys, ["k4", "k3", "k2"], "newest first, oldest dropped");
    clear();
  }

  function test_removeAndClose(t) {
    clear();
    Notifications.notifyLocal("a", "info", "a");
    Notifications.notifyLocal("b", "info", "b");
    const uid = Notifications.toasts.get(1).uid;
    Notifications.close(uid, true);
    t.eq(Notifications.toasts.count, 1);
    t.eq(Notifications.toasts.get(0).key, "b");
    t.eq(Notifications.indexOfUid(uid), -1);
    t.eq(Notifications.indexOfKey("b"), 0);
    Notifications.remove(12345);
    t.eq(Notifications.toasts.count, 1);
    clear();
  }
}
