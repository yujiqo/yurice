# Contributing

Thanks for wanting to help. yurice is small and opinionated, and changes that fit how it's already built get merged fastest. So before writing code, read two things:

1. [The book](book/README.md). It explains every part of yurice from the ground up. You don't have to read all of it, but read Part I and the chapters for the area you want to change. Every guide below points to its chapter.
2. [PHILOSOPHY](PHILOSOPHY.md). It's short, and it's what a pull request is judged against.

For anything bigger than a fix, open an issue first and describe what you want to do. It's much easier to agree on an idea than on a finished pull request that went a different way.

## Branches

yurice has two long-lived branches:

- `main` is stable. Users install from it and update it with `git pull`, so it only ever moves when a release is made.
- `dev` is where work lands. Pull requests are merged here, tested for a while, and then released to `main`.

Always branch from `dev` and open your pull request against `dev`, not `main`. GitHub suggests `main` by default, so check the base branch when you open it.

```sh
git clone https://github.com/<you>/yurice.git ~/yurice
cd ~/yurice
git remote add upstream https://github.com/yujiqo/yurice.git
git switch dev
git switch -c fix/picker-blur
```

Name the branch after what it does: `fix/…`, `feat/…`, `docs/…`. If `dev` moves while you work, rebase onto it (`git fetch upstream && git rebase upstream/dev`) rather than merging it into your branch.

## Setting up

Install your clone the normal way, so your configs link into it:

- On Arch or Debian, run `./install.sh` from your clone. Your `~/.config/niri`, `~/.config/quickshell` and the rest now point at your working copy.
- On NixOS, set the home-manager option `programs.yurice.configDir` to your clone's config folder as a string, for example `"/home/you/yurice/config"`. A string makes the module link to the live folder instead of the Nix store (chapter 23), so edits apply without a rebuild.

From then on, saving a QML file reloads the shell. A few commands you'll use all the time:

```sh
qs log -f              # follow the shell's log
qs kill; qs -d         # restart the shell if a reload got stuck
qs ipc call panel toggle battery   # open things without a keybind
```

Because your real desktop runs your working copy, switching branches switches your desktop too. That's usually what you want. For changes that can lock you out, like the lock screen, the greeter or `install.sh`, test in a virtual machine first: `nixos-rebuild build-vm` on NixOS, or a fresh Arch or Debian VM for the installer. If the shell breaks while locked, [TROUBLESHOOTING](TROUBLESHOOTING.md) has the recovery steps.

## Making a change

These are the common changes, step by step. Each one names the files that must change together.

### A new service

Read chapter 7 first.

1. Create `config/quickshell/services/Name.qml` as a `pragma Singleton` with a `Singleton` root.
2. Expose readonly properties for state and functions for actions. Get data from a quickshell service module if one exists, then from files, then from processes. Poll only when nothing else works.
3. Handle missing hardware: `?.`, `??`, `printErrors: false`, and an `available` flag.
4. If it parses anything from outside (command output, JSON, files), put the parsing in a plain function and add `config/quickshell/tests/TestName.qml` with `test_` functions that call it.

### A new island and panel

Read chapters 10 and 11.

1. Write the panel in `config/quickshell/modules/bar/NamePanel.qml` from the building blocks in chapter 6: `PanelHeader`, `Card`, rows, inputs. Every interactive item follows the keyboard contract.
2. Write the island in `NameIsland.qml`, extending `Island` or `IconIsland`, with `panels: ({ name: namePanel })` and `onClicked: request("name")`.
3. Add it to `Islands.list` in `services/Islands.qml` with its `id`, `icon`, `label` and `panels`. That puts it in the settings page and the mode panel.
4. Add the panel name to `Panels.names` in `services/Panels.qml` so it can be opened by keybind.
5. Place it in `modules/bar/Bar.qml` inside a `BarSlot` with `shown: !Islands.hidden.includes("name")` and `animate: Islands.ready`.
6. Add a keybind (below) and the panel's row to [KEYBINDS](KEYBINDS.md).
7. Add the island id to the `hiddenIslands` list in [CUSTOMIZING](CUSTOMIZING.md).

### A new setting

Read chapters 7 and 15.

1. Add a readonly property in `services/Settings.qml` that reads `values.yourKey ?? default`.
2. Add a row for it in `modules/bar/UserSettings.qml`, usually a `SettingSwitch`, `DurationRow` or `PathRow` with `key: "yourKey"`.
3. Document the key and default in the `settings.json` table in [CUSTOMIZING](CUSTOMIZING.md).

### A new custom hook

Read chapters 21 and 22.

1. Make the program's config load `~/.config/yurice/custom/<program>/<file>` last, and only if it exists.
2. Add it to the hooks table in [CUSTOMIZING](CUSTOMIZING.md).

### A new matugen template

Read chapter 3.

1. Add the template to `config/matugen/templates/`.
2. Add a `[templates.name]` entry to `config/matugen/config.toml` that writes to `~/.cache/yurice/` and has a `post_hook` that reloads the program, ending in `|| true` so a program that isn't running doesn't fail the whole run.
3. Make the program include the generated file, and keep working if it's missing.

### A new keybind

Read chapter 9.

1. If it controls the shell, give the service a function in its `IpcHandler`, with typed arguments.
2. Add the bind to `config/niri/modules/binds.kdl` under the right `// section:` with a `hotkey-overlay-title`, so the cheatsheet shows it.
3. Add it to [KEYBINDS](KEYBINDS.md).

### A new dependency

1. Add the package to `deps/arch/<component>.txt`, `deps/debian/<component>.txt` and `nix/packages.nix`, all three.
2. If Debian doesn't package it, add a pinned upstream build or download to `install.sh`: the tag, commit or URL, and SHA-256 sit together at the top of the file. Use `fetch` and `fetch_source`, which check them (chapter 23).
3. Run `./install.sh --dry-run` on both distros if you can.

When bumping an existing pin, change the tag, commit, URL and SHA-256 together, and get the checksum from the file itself with `sha256sum`, not from a release page.

## Rules

These come from [PHILOSOPHY](PHILOSOPHY.md) and the book. Pull requests that break them get sent back.

- No code comments. Use names that explain themselves. The only comments are the section headers in `Theme.qml` and the `// section:` markers in `binds.kdl`.
- Layers only depend downwards: modules on components and services, components on the theme. Services never draw.
- Every color, size and duration comes from `Theme.qml`. Use roles and semantic aliases, never color literals.
- Reuse components. If two places need the same thing, make it one component.
- Everything works with the keyboard only, through the keyboard contract (chapter 6).
- Services report state that comes back from the system. They don't set it themselves.
- Don't use `MultiEffect`. It crashes quickshell on Qt 6.12. Use `components/Blur.qml`.
- New QML files start with `pragma ComponentBehavior: Bound`.
- The three package lists change together.

## Checks

Before opening a pull request:

```sh
config/quickshell/tests/run.sh       # all tests pass (needs a Wayland session)
config/quickshell/tests/lint.sh      # no new warnings
nix fmt                              # if you touched Nix files
```

QML is formatted with `qmlformat -w 2` and Markdown with prettier. Then try the change for real: with the mouse, with the keyboard only, in both themes (light and dark), and in both modes if it touches anything the second mode hides. Chapter 24 explains the tests and how to write one.

## Docs

Update the docs in the same pull request as the code: the README if users see the change, [CUSTOMIZING](CUSTOMIZING.md) or [KEYBINDS](KEYBINDS.md) if it adds a setting, hook or key, and the book chapter that covers the area. Book snippets link to line ranges in the source. If your change moves code a snippet points at, fix the numbers.

The README is casual and lowercase. Everything in `docs/` uses normal capitalization, plain words and paragraphs, no bold or italics unless really needed, and no recap at the end. Be concrete, and leave a TODO rather than guess.

## Commits and pull requests

Commit messages are one short lowercase line in the imperative, starting with the area they touch:

```text
bar: make battery profile change smooth
lock: relock after a shell crash
install: build matugen from source on aarch64
docs: explain the display editor
```

Use the part of yurice you changed as the area: `bar`, `lock`, `greeter`, `wallpaper`, `launcher`, `screenshot`, `theme`, `niri`, `kitty`, `fish`, `tmux`, `nvim`, `matugen`, `install`, `nix`, `tests` or `docs`. If a change really spans several, pick the main one. Release notes are grouped by these areas, so they matter.

Pull requests are squash-merged into `dev`, so the pull request title becomes the commit and follows the same format. In the description, say what changed and why, how you tested it, and add a screenshot or short recording for anything visual. Keep one change per pull request. A fix and an unrelated refactor are two pull requests. If your change is breaking (see Releases below), say so at the top of the description.

## AI tools

Using AI coding tools is fine. yurice is built with Claude Code. [AGENTS.md](../AGENTS.md) at the root holds the rules above in a form agents read on their own, and `CLAUDE.md` imports it for Claude Code. You're still responsible for every line: read the diff, run the checks, and make sure it fits the book's patterns rather than inventing new ones.

## Releases

This part is for the maintainer, but it's here so everyone knows how changes reach `main`.

Versions follow semantic versioning, starting from 1.0.0. The patch number goes up for fixes only (1.0.1), and the minor number for new features that don't break anything (1.1.0). The major number (2.0.0) goes up when updating would break someone's setup without them doing anything, which for yurice means any of these:

- a path in `~/.config/yurice/custom/` or a key file is renamed or removed;
- a `settings.json` key is renamed, removed, or changes meaning;
- an IPC target or function is renamed or removed, since people call them from their own scripts and binds;
- a NixOS or home-manager option is renamed or removed, or an `install.sh` flag or component changes;
- a state file changes format in a way old files can't be read.

Changing a default keybind, a look or an animation isn't breaking. Mention it in the release notes anyway.

When `dev` has been stable for a while:

```sh
git switch main
git merge --ff-only dev
git tag -a v1.1.0 -m v1.1.0
git push origin main v1.1.0
```

`main` only fast-forwards to `dev`, so the two never diverge. Pushing the tag starts [the release workflow](../.github/workflows/release.yml), which creates a GitHub release with notes built from the commit messages since the previous tag, grouped by area. The notes can be edited on GitHub afterwards. A tag with a hyphen, like `v2.0.0-rc.1`, is published as a pre-release.
