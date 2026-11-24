# 1. The pieces

Before writing any code, it helps to know what we're building and what we're building it on. yurice isn't one program. It's a handful of programs that work together, and this chapter is the map. Every later chapter zooms into one spot on it.

## What you see

Log in and you see a login screen with your wallpaper and avatar. After that come your windows, laid out in columns that scroll sideways. At the top sits a bar made of separate rounded "islands", and clicking one grows it into a panel. Behind everything is the wallpaper, and every color on screen comes from it, including your terminal and your editor.

Each of these is a different program, or a different part of the same one.

## The programs

### niri: the compositor

[niri](https://github.com/YaLTeR/niri) is the Wayland compositor. It owns the screen, draws the windows and handles input. It's a scrolling tiling window manager: windows sit in columns on an endless horizontal strip, and you scroll the strip instead of squeezing windows to fit like in Hyprland.

niri doesn't draw a bar, a launcher or a wallpaper. It leaves those to other programs and talks to them in two ways. The first is keybinds that run commands. When you press `Alt+Space`, niri runs `qs ipc call launcher toggle`. It has no idea what a launcher is, it just runs the command. The second is an IPC socket: niri publishes a stream of events on a Unix socket (a workspace changed, a window opened) and accepts actions back on it ("focus workspace 3").

Its config lives in [`config/niri/`](../../config/niri). Chapter 21 covers it.

### quickshell: the shell

[quickshell](https://quickshell.org) is a toolkit for building desktop shells in QML, the declarative UI language from Qt. You write `.qml` files describing windows and what's in them, and quickshell turns them into real Wayland surfaces: a bar glued to the top edge, an overlay over everything, a lock screen.

Almost everything on screen that isn't an app window is quickshell running yurice's QML:

- the bar and its panels
- the launcher and the clipboard history
- the wallpaper and the wallpaper picker
- the lock screen
- the screenshot tool
- the login screen (greeter)

It all lives in [`config/quickshell/`](../../config/quickshell), and it's what most of this book is about.

### matugen: the colors

[matugen](https://github.com/InioX/matugen) takes an image, pulls a Material You palette out of it, and fills in templates with those colors. yurice has one template per program that should follow the wallpaper:

```text
config/matugen/templates/
├── quickshell.json   → ~/.cache/yurice/colors.json
├── kitty.conf        → ~/.cache/yurice/kitty-colors.conf
├── niri.kdl          → ~/.cache/yurice/niri-colors.kdl
├── nvim.lua          → ~/.cache/yurice/nvim-colors.lua
├── tmux.conf         → ~/.cache/yurice/tmux-colors.conf
└── fastfetch.jsonc   → ~/.cache/yurice/fastfetch.jsonc
```

After writing each file, matugen runs a post hook that tells the program to reload. kitty, for example, gets `pkill -USR1 kitty`. Chapter 3 follows this all the way through.

### The terminal side

kitty, fish, starship, tmux, neovim, lazygit and fastfetch each have a plain config in [`config/`](../../config). They don't depend on the shell at all, so you can use only the terminal part of yurice on a Mac, and the author does. Chapter 22 covers them.

## How they connect

```text
                    ┌──────────────┐
   keybind ───────► │     niri     │ ──── draws windows
                    └──────┬───────┘
          spawn "qs ipc …" │   ▲ event stream / actions
                           ▼   │  ($NIRI_SOCKET)
                    ┌──────────────┐
                    │  quickshell  │ ──── bar, panels, wallpaper, lock, …
                    └──────┬───────┘
          "matugen image …"│
                           ▼
                    ┌──────────────┐        ~/.cache/yurice/
                    │   matugen    │ ──────► colors.json, kitty-colors.conf,
                    └──────────────┘         niri-colors.kdl, nvim-colors.lua, …
                                                    │
                     quickshell, kitty, niri, ◄─────┘ (each reloads its file)
                     nvim, tmux, fastfetch
```

No program knows the others exist. They share files in agreed places and commands, nothing else. That loose coupling is why you can use the terminal half without the desktop half, and why any piece can be replaced on its own.

## Where things live

Four directories come up again and again in this book:

| Directory                  | What's in it                                | Who writes it           |
| -------------------------- | ------------------------------------------- | ----------------------- |
| `config/` in the repo      | every config and all the QML                | you, through git        |
| `~/.config/yurice/custom/` | your personal overrides and `settings.json` | you and the user island |
| `~/.local/state/yurice/`   | what the shell remembers between runs       | the shell               |
| `~/.cache/yurice/`         | generated colors and thumbnails             | matugen and the shell   |

`config/` is linked into `~/.config/` (`~/.config/niri` → `repo/config/niri`, and so on), so editing a file in the repo changes the live desktop. That's how yurice is developed, and it's how you should read this book: the file open in one window, the result in another.

## The quickshell folder

Most of the book happens in [`config/quickshell/`](../../config/quickshell):

```text
config/quickshell/
├── shell.qml        # entry point for your session
├── greeter.qml      # entry point for the login screen
├── theme/           # Theme.qml: every color, size and duration
├── components/      # small reusable pieces: labels, sliders, islands…
├── services/        # singletons that talk to the system: audio, niri, wifi…
├── modules/         # the actual UI, built from components and services
│   ├── bar/         # the bar, its islands and all their panels
│   ├── wallpaper/   # the wallpaper, picker, intro and outro
│   ├── lock/        # the lock screen
│   ├── greeter/     # the login screen
│   └── screenshot/  # the screenshot overlay
├── scripts/         # small shell scripts the services call
├── shaders/         # one GPU shader, for rounded images
└── tests/           # the headless test runner and lint
```

The layers only depend downwards:

```text
modules   →   components + services   →   theme
```

A module uses components and services. A service never draws anything. A component only knows the theme and never talks to the system, with three exceptions that services build on: `Poller` runs a command on a timer, `KeyFile` reads and writes a key file, and `SearchFeed` does the paging and downloading shared by the two image searches.

That's why a slider can be reused anywhere, and why the audio code doesn't break when the volume panel is redesigned.
