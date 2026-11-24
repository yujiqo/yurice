# The yurice book

This is the long way around. The [README](../../README.md) tells you what yurice does. This book tells you how it's made, starting from a single QML rectangle and ending with the full desktop: bar, panels, lock screen, greeter, terminal and installer.

You don't need to know QML to start. You need some patience, a running yurice (or a niri session with quickshell installed), and a terminal next to the book so you can open the files it talks about.

## How to read it

Read it in order, at least the first time. Every chapter uses what the previous ones built, and Part I is the foundation for everything else.

Keep the source open. Each chapter links the real files, often down to the line, and the snippets are copied from the repo. When a snippet is a cut-down version made to explain an idea, it says "simplified".

Try things as you go. quickshell reloads the moment you save a file, so the fastest way to understand a property is to change it and watch. Each part ends at a natural place to stop.

If you want to contribute, read this book, then [PHILOSOPHY.md](../PHILOSOPHY.md), then [CONTRIBUTING.md](../CONTRIBUTING.md).

## Contents

### Part I: Foundations

1. [The pieces](01-the-pieces.md): niri, quickshell, matugen and the configs, and how they talk to each other
2. [QML in one sitting](02-qml-in-one-sitting.md): just enough QML and quickshell to read the rest
3. [The theme](03-the-theme.md): one file of tokens, and how a wallpaper becomes colors
4. [Primitives](04-primitives.md): text, icons, rounded images and the small pieces everything is made of
5. [Motion](05-motion.md): building a spring from scratch, then everything that moves with it
6. [Building blocks](06-building-blocks.md): cards, rows, switches, sliders and lists that every panel shares

### Part II: Talking to the system

1. [Services](07-services.md): singletons that know what the system is doing, and where they keep what they remember
2. [Talking to niri](08-talking-to-niri.md): the event stream, a live copy of workspaces and windows, and sending actions back
3. [IPC and keybinds](09-ipc-and-keybinds.md): how a key in niri opens a panel, and the cheatsheet parsed from binds.kdl

### Part III: The bar

1. The bar
2. Islands that become panels
3. Keyboard everywhere
4. System islands
5. The outside world
6. The user island
7. Two modes

### Part IV: Beyond the bar

1. Wallpapers and color
2. Launcher, clipboard, power and toasts
3. Screenshots
4. Lock screen, greeter and session

### Part V: The rest of the desktop

1. The niri config
2. The terminal

### Part VI: Shipping it

1. Installing
2. Tests and lint

### Appendix

- Glossary
