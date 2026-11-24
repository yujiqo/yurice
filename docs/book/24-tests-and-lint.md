# 24. Tests and lint

A shell is hard to test the usual way. Most of what can go wrong is visual, or needs real hardware, or a real compositor. yurice doesn't try to test all of that. It tests what can be tested cheaply and catches the most common breakage: a QML file that no longer compiles, a component that can't be created, a parser that misreads its input, or a service whose logic went wrong. Everything lives in [`config/quickshell/tests/`](../../config/quickshell/tests), and one command runs it:

```sh
config/quickshell/tests/run.sh
```

It prints `N passed, M failed` at the end. Pass a word to run only the matching tests, like `tests/run.sh Niri`.

## How the runner works

There's no test framework. quickshell itself is the test runner. [`run.sh`](../../config/quickshell/tests/run.sh) builds a throwaway config folder, starts quickshell on it, and reads the results from its log.

### An isolated world

The script makes a temporary folder with its own `config`, `home`, `run` and `bin`:

```sh
mkdir -p "$work/config" "$work/home" "$work/bin"
mkdir -m 700 "$work/run"
for dir in components services theme modules shaders scripts tests; do
  ln -s "$root/$dir" "$work/config/$dir"
done

for cmd in bluetoothctl brightnessctl busctl cliphist curl dconf identify magick matugen niri qalc \
  realesrgan-ncnn-vulkan systemctl systemd-inhibit wl-copy wl-paste wtype notify-send loginctl; do
  printf '#!/bin/sh\nexit 1\n' > "$work/bin/$cmd"
  chmod +x "$work/bin/$cmd"
done
```

[`config/quickshell/tests/run.sh:34-44`](../../config/quickshell/tests/run.sh#L34-L44)

The real source folders are linked in, so tests run against your working copy. Every external command the services call is replaced with a fake that just fails, and the fake `bin` goes first in `PATH`. A test run can never suspend your laptop, change your brightness, run matugen over your colors, or talk to danbooru. It also proves the services survive their commands failing, which is chapter 7's "never trust the hardware" rule tested for free.

quickshell is then started with `HOME`, every `XDG_*` folder and `XDG_RUNTIME_DIR` pointed into the temporary folder, `NIRI_SOCKET` and the D-Bus address removed, and its own private D-Bus from `dbus-run-session`. Your real settings, state and keys are never read or written. It does need a running Wayland session, because quickshell needs somewhere to create windows.

Instead of `shell.qml`, the temporary config gets a tiny one that imports every module and creates a `Runner`.

### Three kinds of checks

[`Runner.qml`](../../config/quickshell/tests/Runner.qml) does three passes, printing `@@PASS name` or `@@FAIL name: reason` for each check, and `@@DONE` at the end. `run.sh` waits for `@@DONE`, then counts.

The smoke pass compiles every QML file in `components`, `modules`, `services` and `theme`. A typo, a wrong import or a missing property fails here, even in a file nothing else loads yet.

The test pass loads every `Test*.qml` file, and runs each function whose name starts with `test_`, passing it a small assert object with `eq`, `ok` and `near`. `eq` compares by structure, with object keys sorted, so `t.eq(list, [1, 2])` and `t.eq(obj, { a: 1 })` work as you'd expect. Tests run one per timer tick, 20 ms apart, so bindings and `Qt.callLater` calls get to settle between them.

The instantiate pass creates every component and every bar module once, on a hidden 1280×720 item, and destroys it. Before that, [`Fixtures.qml`](../../config/quickshell/tests/Fixtures.qml) loads believable data into the services: two workspaces through `Niri.handleEvent`, two toasts, a parsed `binds.kdl` snippet, a clipboard list with an image, a 4K monitor, and a weather forecast. So every panel is created with something to show, and code paths that only run with data are exercised too. Singletons and top-level windows are skipped. Components with `required` properties get them from a small table in the runner.

Finally, `run.sh` scans the log for JavaScript runtime errors (`TypeError`, `ReferenceError`, "Unable to assign", and similar) and counts each one as a failure. A binding that throws while a panel is created doesn't stop anything, it just logs a warning, and this is what turns those warnings into failures.

Before starting quickshell at all, `run.sh` also checks every script in `scripts/` with `sh -n` and fails on trailing whitespace in any QML or shell file.

## Writing a test

A test file is a QML object with `test_` functions. Since it's QML, it can contain real components to test against. Here's part of the spring's tests:

```qml
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
```

[`config/quickshell/tests/TestSpring.qml`](../../config/quickshell/tests/TestSpring.qml)

The first test checks something that's easy to break: `snap()` sets `value`, and must not replace the binding on `target`. Each test cleans up after itself (`suite.shown = true`), since tests in a file share their objects.

Services are singletons, so tests call them directly. [`TestNiri.qml`](../../config/quickshell/tests/TestNiri.qml) feeds `Niri.handleEvent` made-up events and checks the workspace list (chapter 8). [`TestHotkeys.qml`](../../config/quickshell/tests/TestHotkeys.qml) parses bind lines. [`TestIslands.qml`](../../config/quickshell/tests/TestIslands.qml) checks that hidden islands refuse their panels. That's the pattern from chapter 8 again: when the logic is a plain function that takes data, the test is a few lines.

What's worth a test:

- parsers of outside data: niri events, `binds.kdl`, `cliphist` lines, `niri msg outputs`, API responses;
- pure logic: scoring, snapping, time formatting, schedule math;
- contracts between parts: `Panels.open` refusing a hidden island, `Island` following `host.dropdown`.

What isn't: how things look, and anything that needs real hardware. Those are checked by running the shell.

## Lint

[`tests/lint.sh`](../../config/quickshell/tests/lint.sh) runs Qt's `qmllint` over every QML file outside `tests/`. qmllint needs to know where quickshell's types are, and quickshell writes that into `.qmlls.ini` the first time it runs a config, so the script reads the import paths from there:

```sh
ini=.qmlls.ini
if [ ! -r "$ini" ]; then
  echo "$ini is missing: start the shell once with quickshell so it generates the import paths" >&2
  exit 2
fi
```

[`config/quickshell/tests/lint.sh:7-11`](../../config/quickshell/tests/lint.sh#L7-L11)

It prints the warnings, leaving out the `[unqualified]` category, and then a count per category. Lint is advisory and never fails the run. Use it to check that a change didn't add new warnings.

The same `.qmlls.ini` lets the QML language server in neovim (chapter 22) understand quickshell's types while you edit.

## Formatting

QML is formatted with `qmlformat -w 2`, which neovim runs on save through efm (chapter 22). Nix files are formatted with alejandra, which the flake exports as its formatter, so `nix fmt` formats every Nix file in the repo. The Markdown docs are formatted with prettier.

## Shaders

There's one shader, and it's not built by tests. After editing [`shaders/roundedimage.frag`](../../config/quickshell/shaders/roundedimage.frag), run [`shaders/build.sh`](../../config/quickshell/shaders/build.sh), which compiles every `.frag` into a `.qsb` with Qt's `qsb` tool, taken from nixpkgs with `nix shell`. Commit both files.

## Before you commit

1. `config/quickshell/tests/run.sh` passes.
2. `config/quickshell/tests/lint.sh` shows no new warnings.
3. New QML is formatted, and `nix fmt` if you touched Nix.
4. You tried the change in the running shell, with the mouse and with only the keyboard.

[CONTRIBUTING](../CONTRIBUTING.md) has the rest: how to set up a working copy, recipes for common changes, and commit style.
