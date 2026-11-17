# The yurice book

This is the long way around. The [README](../../README.md) tells you what yurice does. This book tells you **how it's made**, starting from a single QML rectangle and ending with the full desktop: bar, panels, lock screen, greeter, terminal and installer.

You don't need to know QML to start. You need some patience, a running yurice (or a niri session with quickshell installed), and a terminal next to the book so you can open the files it talks about.

## How to read it

- **In order, at least at first.** Every chapter uses what the previous ones built. Part I is the foundation for everything else.
- **With the source open.** Each chapter links the real files, often down to the line. The snippets in the book are copied from the repo. When a snippet is a cut-down version made to explain an idea, it says _simplified_.
- **Trying things.** quickshell reloads the moment you save a file, so the fastest way to understand a property is to change it and watch.
- **One part at a time.** Each part ends at a natural stopping point.

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

7. Services
8. Talking to niri
9. IPC and keybinds

### Part III: The bar

10. The bar
11. Islands that become panels
12. Keyboard everywhere
13. System islands
14. The outside world
15. The user island
16. Two modes

### Part IV: Beyond the bar

17. Wallpapers and color
18. Launcher, clipboard, power and toasts
19. Screenshots
20. Lock screen, greeter and session

### Part V: The rest of the desktop

21. The niri config
22. The terminal

### Part VI: Shipping it

23. Installing
24. Tests and lint

### Appendix

- Glossary
