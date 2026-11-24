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

- [1. The pieces](01-the-pieces.md): niri, quickshell, matugen and the configs, and how they talk to each other
- [2. QML in one sitting](02-qml-in-one-sitting.md): just enough QML and quickshell to read the rest
- [3. The theme](03-the-theme.md): one file of tokens, and how a wallpaper becomes colors
- [4. Primitives](04-primitives.md): text, icons, rounded images and the small pieces everything is made of
- [5. Motion](05-motion.md): building a spring from scratch, then everything that moves with it
- [6. Building blocks](06-building-blocks.md): cards, rows, switches, sliders and lists that every panel shares

### Part II: Talking to the system

- [7. Services](07-services.md): singletons that know what the system is doing, and where they keep what they remember
- [8. Talking to niri](08-talking-to-niri.md): the event stream, a live copy of workspaces and windows, and sending actions back
- [9. IPC and keybinds](09-ipc-and-keybinds.md): how a key in niri opens a panel, and the cheatsheet parsed from binds.kdl

### Part III: The bar

- [10. The bar](10-the-bar.md): one tall window per screen, the input mask, and islands that come and go
- [11. Islands that become panels](11-islands-that-become-panels.md): how a pill grows into its panel, and when it closes again
- [12. Keyboard everywhere](12-keyboard-everywhere.md): focus, directional navigation and the keys every panel gets for free
- [13. System islands](13-system-islands.md): workspaces, network, Bluetooth, volume, battery, clock and media
- [14. The outside world](14-the-outside-world.md): weather, wallhaven and danbooru, and requests that arrive late
- [15. The user island](15-the-user-island.md): settings, idle, the avatar editor and the display editor
- [16. Two modes](16-two-modes.md): one service that decides what the second mode hides

### Part IV: Beyond the bar

- [17. Wallpapers and color](17-wallpapers-and-color.md): the wallpaper list, the picker, matugen, light and dark, upscaling and the greeter copy
- [18. Launcher, clipboard, power and toasts](18-launcher-clipboard-power-and-toasts.md): app search, the calculator, pasting from history, the power menu and notifications
- [19. Screenshots](19-screenshots.md): freezing the screen, selecting on the pixel grid, and saving
- [20. Lock screen, greeter and session](20-lock-screen-greeter-and-session.md): session lock, PAM, locking before sleep, crash recovery and greetd

### Part V: The rest of the desktop

- [21. The niri config](21-the-niri-config.md): includes and their order, input, layout, rules, and your own additions
- [22. The terminal](22-the-terminal.md): kitty, fish, starship, tmux, neovim, lazygit, less and fastfetch, and how each follows the wallpaper

### Part VI: Shipping it

- 23. Installing
- 24. Tests and lint

### Appendix

- Glossary
