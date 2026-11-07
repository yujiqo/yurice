pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
  id: root

  readonly property int maxToasts: 3
  readonly property int defaultTimeout: 5000
  readonly property alias toasts: model
  property int nextUid: 1
  property var sources: ({})

  function indexOfUid(uid) {
    for (let i = 0; i < model.count; i++)
      if (model.get(i).uid === uid)
        return i;
    return -1;
  }

  function indexOfKey(key) {
    for (let i = 0; i < model.count; i++)
      if (model.get(i).key === key)
        return i;
    return -1;
  }

  function source(uid) {
    return sources[uid] ?? null;
  }

  function iconFor(n) {
    const candidates = [n.appIcon, DesktopEntries.byId(n.desktopEntry)?.icon ?? ""];
    for (const c of candidates) {
      if (!c)
        continue;
      if (c.startsWith("/") || c.startsWith("file://") || c.startsWith("image://"))
        return c;
      const path = Quickshell.iconPath(c, true);
      if (path)
        return path;
    }
    return "";
  }

  function timeoutFor(n) {
    if (n.urgency === NotificationUrgency.Critical)
      return 0;
    return n.expireTimeout > 0 ? Math.round(n.expireTimeout * 1000) : defaultTimeout;
  }

  function fields(n) {
    return {
      appName: n.appName || "Notification",
      summary: n.summary,
      body: n.body,
      appIcon: iconFor(n),
      image: n.image,
      symbol: "",
      critical: n.urgency === NotificationUrgency.Critical,
      timeout: timeoutFor(n)
    };
  }

  function push(entry) {
    model.insert(0, entry);
    while (model.count > maxToasts)
      close(model.get(model.count - 1).uid, false);
  }

  function addNotification(n) {
    for (const uid in sources) {
      if (sources[uid] === n) {
        const i = indexOfUid(parseInt(uid));
        if (i >= 0) {
          model.set(i, Object.assign(fields(n), {
            generation: model.get(i).generation + 1
          }));
          return;
        }
      }
    }
    const uid = nextUid++;
    const next = Object.assign({}, sources);
    next[uid] = n;
    sources = next;
    n.closed.connect(() => root.remove(uid));
    push(Object.assign(fields(n), {
      uid: uid,
      key: "",
      generation: 0
    }));
  }

  function notifyLocal(key, symbol, summary, body, timeout) {
    const entry = {
      appName: "",
      summary: summary,
      body: body ?? "",
      appIcon: "",
      image: "",
      symbol: symbol,
      critical: false,
      timeout: timeout ?? 1500
    };
    const i = indexOfKey(key);
    if (i >= 0) {
      model.set(i, Object.assign(entry, {
        generation: model.get(i).generation + 1
      }));
      return;
    }
    push(Object.assign(entry, {
      uid: nextUid++,
      key: key,
      generation: 0
    }));
  }

  function remove(uid) {
    const i = indexOfUid(uid);
    if (i >= 0)
      model.remove(i);
    if (sources[uid]) {
      const next = Object.assign({}, sources);
      delete next[uid];
      sources = next;
    }
  }

  function close(uid, byUser) {
    const n = sources[uid];
    remove(uid);
    if (n)
      byUser ? n.dismiss() : n.expire();
  }

  function activate(uid) {
    const n = sources[uid];
    const action = n?.actions.find(a => a.identifier === "default");
    if (action)
      action.invoke();
    close(uid, true);
  }

  function invoke(uid, identifier) {
    const n = sources[uid];
    n?.actions.find(a => a.identifier === identifier)?.invoke();
    close(uid, true);
  }

  ListModel {
    id: model
  }

  NotificationServer {
    keepOnReload: true
    actionsSupported: true
    imageSupported: true
    bodySupported: true
    bodyMarkupSupported: false
    persistenceSupported: true
    onNotification: n => {
      n.tracked = true;
      root.addNotification(n);
    }
  }
}
