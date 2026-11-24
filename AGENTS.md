# AGENTS.md

Instructions for AI coding agents working on yurice. Humans should read [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) instead. Everything here is also in there.

## What this is

yurice is a desktop for niri built with quickshell (QML), themed by matugen, plus configs for kitty, fish, starship, tmux, neovim, lazygit, less and fastfetch. Configs live in `config/` and are symlinked into `~/.config`, so edits apply to the running desktop. [`docs/book/`](docs/book/README.md) explains how every part is built. Read the chapter for the area you're changing before you change it.

## Layout

- `config/quickshell/`: the shell. `theme/` (tokens), `components/` (reusable pieces), `services/` (singletons that talk to the system), `modules/` (the UI), `scripts/`, `shaders/`, `tests/`.
- `config/niri/`, `config/matugen/` and one folder per terminal program.
- `install.sh` and `deps/{arch,debian}/*.txt`: the Arch and Debian installer and its package lists.
- `flake.nix` and `nix/`: the NixOS and home-manager modules, with `nix/packages.nix` as the Nix package list.
- `dist/`: greeter, systemd units and other files the installers place.
- `docs/`: README-level docs, and the book in `docs/book/`.

## Rules

- No code comments. Use clear names instead. The only comments are the section headers in `Theme.qml` and the `// section:` markers in `binds.kdl`, which the cheatsheet parses.
- Layers only depend downwards: modules use components and services, components use the theme, services never draw. Components don't run commands, except `Poller`, `KeyFile` and `SearchFeed`.
- Every color, size and duration comes from `Theme.qml`. Use Material roles or semantic aliases, never color literals. A value used in more than one place becomes a token.
- Reuse what's in `components/` before writing something new. If two places need the same thing, make it one component.
- Everything works with the keyboard only. Interactive components set `activeFocusOnTab: true`, contain `FocusRing {}`, and define `keyActivate()` or a `clicked` signal, and `keyAdjust(direction)` for left/right adjustment.
- Services expose readonly properties and functions. After asking the system to change something, let the new value come back from the system instead of setting it yourself. Assign new objects to `var` properties instead of mutating them, or bindings won't update.
- Never trust hardware or files to exist. Use `?.`, `??`, `printErrors: false` and an `available` or `ready` flag.
- Don't use `MultiEffect` from `QtQuick.Effects`. It crashes quickshell on Qt 6.12. Use `components/Blur.qml` or `ShaderEffectSource`.
- Every new file starts with `pragma ComponentBehavior: Bound`. Format QML with `qmlformat -w 2`.
- Dependencies change in `deps/arch/`, `deps/debian/` and `nix/packages.nix` together. Pinned versions in `install.sh` change tag, commit, URL and SHA-256 together.
- User files belong in the right place: settings in `~/.config/yurice/custom/quickshell/settings.json`, keys in `~/.config/yurice/*.key`, state in `~/.local/state/yurice/`, generated files in `~/.cache/yurice/`. Every config ends by loading its optional file from `~/.config/yurice/custom/`.

## Checks

Run these before you call a change done:

```sh
config/quickshell/tests/run.sh      # needs a Wayland session
config/quickshell/tests/lint.sh     # advisory: no new warnings
nix fmt                             # if Nix files changed
```

Add a `Test*.qml` file with `test_` functions in `config/quickshell/tests/` for new parsing or logic. If you change a shader, rebuild it with `config/quickshell/shaders/build.sh` and keep the `.qsb`.

## Docs

Docs change in the same change as the code. That means the README, `docs/*.md` and the book chapter that covers the area. Book snippets are copied from the source and link to line ranges like `Foo.qml#L10-L20`. When you move code, update those line numbers.

The README is casual and lowercase. Everything in `docs/` uses normal capitalization and follows these rules:

- Be direct and concrete: real names, numbers and paths. If a detail is unknown, leave a TODO instead of guessing.
- Plain words. Avoid "leverage", "delve", "seamless", "robust" and similar.
- Paragraphs by default. Use bullets only for real lists.
- No bold or italics except where truly needed, and em dashes only rarely.
- No intro fluff and no recap endings.

## Git

- Work happens on `dev`. `main` only receives tested releases, so never commit to `main` directly.
- User-visible changes get a line under `## [Unreleased]` in `CHANGELOG.md`, written for users.
- Commit messages are `area: short lowercase imperative`, like `bar: make battery profile smooth` or `install: build matugen on aarch64`. See CONTRIBUTING for the areas.
- Don't commit, push, tag or open pull requests unless the person you're working with asks for it.
