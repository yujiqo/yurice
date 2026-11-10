import Quickshell
import QtQuick

QtObject {
  id: root

  readonly property var smokeFiles: Quickshell.env("YURICE_SMOKE").split(":").filter(f => f !== "")
  readonly property var testFiles: Quickshell.env("YURICE_TESTS").split(":").filter(f => f !== "")
  readonly property string filter: Quickshell.env("YURICE_FILTER") ?? ""

  function canonical(value) {
    if (Array.isArray(value))
      return "[" + value.map(canonical).join(",") + "]";
    if (value !== null && typeof value === "object")
      return "{" + Object.keys(value).sort().map(k => JSON.stringify(k) + ":" + canonical(value[k])).join(",") + "}";
    return JSON.stringify(value);
  }

  readonly property var assert: ({
      eq: (actual, expected, message) => {
        const a = root.canonical(actual);
        const e = root.canonical(expected);
        if (a !== e)
          throw new Error(`${message ? message + ": " : ""}expected ${e}, got ${a}`);
      },
      ok: (value, message) => {
        if (!value)
          throw new Error(message ?? "expected truthy value");
      },
      near: (actual, expected, epsilon, message) => {
        if (Math.abs(actual - expected) > (epsilon ?? 1e-9))
          throw new Error(`${message ? message + ": " : ""}expected ${expected}, got ${actual}`);
      }
    })

  function report(ok, name, message) {
    console.log(ok ? `@@PASS ${name}` : `@@FAIL ${name}: ${String(message).replace(/\n/g, " | ")}`);
  }

  function selected(name) {
    return root.filter === "" || name.includes(root.filter);
  }

  function smoke() {
    for (const file of smokeFiles) {
      const name = `compile ${file}`;
      if (!selected(name))
        continue;
      const component = Qt.createComponent(Qt.resolvedUrl("../" + file), Component.PreferSynchronous);
      report(component.status === Component.Ready, name, component.errorString());
    }
  }

  property var queue: []

  function collect() {
    const list = [];
    for (const file of testFiles) {
      const component = Qt.createComponent(Qt.resolvedUrl(file + ".qml"), Component.PreferSynchronous);
      if (component.status !== Component.Ready) {
        report(false, file, component.errorString());
        continue;
      }
      const suite = component.createObject(root);
      for (const key in suite) {
        const name = `${file}.${key}`;
        if (key.startsWith("test_") && typeof suite[key] === "function" && selected(name))
          list.push({
            name: name,
            suite: suite,
            key: key
          });
      }
    }
    return list;
  }

  readonly property var instantiateFiles: Quickshell.env("YURICE_INSTANTIATE").split(":").filter(f => f !== "")
  readonly property var requiredProperties: ({
      "modules/bar/LevelsPanel.qml": {
        kind: "volume"
      }
    })

  property Item stage: Item {
    visible: false
    width: 1280
    height: 720
  }

  function instantiate() {
    const fixtures = Qt.createComponent(Qt.resolvedUrl("Fixtures.qml"), Component.PreferSynchronous);
    if (fixtures.status !== Component.Ready) {
      report(false, "fixtures", fixtures.errorString());
      return;
    }
    fixtures.createObject(root).apply();
    for (const file of instantiateFiles) {
      const name = `instantiate ${file}`;
      if (!selected(name))
        continue;
      const component = Qt.createComponent(Qt.resolvedUrl("../" + file), Component.PreferSynchronous);
      const object = component.createObject(stage, requiredProperties[file] ?? {});
      report(object !== null, name, component.errorString() || "createObject returned null");
      object?.destroy();
    }
  }

  function step() {
    if (queue.length === 0) {
      ticker.stop();
      instantiate();
      console.log("@@DONE");
      return;
    }
    const test = queue.shift();
    try {
      test.suite[test.key](assert);
      report(true, test.name);
    } catch (e) {
      report(false, test.name, e.message ?? e);
    }
  }

  property Timer ticker: Timer {
    interval: 20
    repeat: true
    onTriggered: root.step()
  }

  Component.onCompleted: {
    smoke();
    queue = collect();
    ticker.start();
  }
}
