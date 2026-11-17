# 1. The pieces

Before writing any code, it helps to know what we're building and what we're building it _on_. yurice isn't one program. It's a bunch of programs that work together. This chapter is the map. Every later chapter focuses on something from here.

## What you see

Log in and you see four things:

1. **A login screen.** It shows your wallpaper and avatar.
2. **Windows.** They're laid out in columns that scroll sideways.
3. **A bar** at the top, made of separate rounded "islands". Click one and it grows into a panel.
4. **The wallpaper** behind it all. Every color on screen comes from it, including your terminal and your editor.

Each of these is a different program, or a different part of the same one.

## The programs

### niri: the compositor

[niri](https://github.com/YaLTeR/niri) is the Wayland compositor. It owns the screen, draws the windows and handles input. It's a _scrolling tiling_ window manager, so windows sit in columns on an endless horizontal strip, and you scroll the strip instead of squeezing windows to fit like like in hyperland for example.

niri does **not** draw a bar, a launcher or a wallpaper. It leaves those to other programs, and talks to them in two ways:

- **Keybinds that run commands.** When you press `Alt+Space`, niri runs `qs ipc call launcher toggle`. niri doesn't know what a launcher is. It just runs the command.
- **An IPC socket.** niri publishes a stream of events (a workspace changed, a window opened) on a Unix socket, and accepts actions back on it ("focus workspace 3").

Its config lives in [`config/niri/`](../../config/niri). Chapter 21 covers it.

### quickshell: the shell

[quickshell](https://quickshell.org) is a toolkit for building desktop shells in Qt Meta-Object Language (QML), the declarative UI language from Qt. You write `.qml` files describing windows and what's in them, and quickshell turns them into real Wayland surfaces: a bar glued to the top edge, an overlay over everything, a lock screen, etc.

Almost everything you _see_ that isn't an app window is quickshell running yurice's QML:

- the bar and its panels
- the launcher and the clipboard history
- the wallpaper
- the wallpaper picker
- the lock screen
- the screenshot tool
- the login screen (greeter)

It all lives in [`config/quickshell/`](../../config/quickshell), and it's what the most of this book is about.

### matugen: the colors

[matugen](https://github.com/InioX/matugen) takes an image, pulls a Material You palette out of it, and fills in **templates** with those colors. yurice has one template per program that should follow the wallpaper:

```text
config/matugen/templates/
├── quickshell.json   → ~/.cache/yurice/colors.json
├── kitty.conf        → ~/.cache/yurice/kitty-colors.conf
├── niri.kdl          → ~/.cache/yurice/niri-colors.kdl
├── nvim.lua          → ~/.cache/yurice/nvim-colors.lua
├── tmux.conf         → ~/.cache/yurice/tmux-colors.conf
└── fastfetch.jsonc   → ~/.cache/yurice/fastfetch.jsonc
```

After writing each file, matugen runs a small _post hook_ that tells the program to reload. For example, kitty gets `pkill -USR1 kitty`. Chapter 3 follows this all the way through.

### The terminal side

kitty, fish, starship, tmux, neovim, lazygit and fastfetch each have a plain config in [`config/`](../../config). They don't depend on the shell at all. You can use only the terminal part of yurice on a Mac, and the author does. Chapter 22 covers them.

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

No program knows the others exist. They only share **files in agreed places** and **commands**. That loose coupling is why you can use the terminal half without the desktop half, and why every piece can be replaced on its own.

## Where things live

Four directories show up again and again in this book. They're worth learning now:

| Directory                  | What's in it                                | Who writes it           |
| -------------------------- | ------------------------------------------- | ----------------------- |
| `config/` in the repo      | every config and all the QML                | you, through git        |
| `~/.config/yurice/custom/` | your personal overrides and `settings.json` | you and the user island |
| `~/.local/state/yurice/`   | what the shell remembers between runs       | the shell               |
| `~/.cache/yurice/`         | generated colors and thumbnails             | matugen and the shell   |

`config/` is linked into `~/.config/` (`~/.config/niri` → `repo/config/niri`, and so on), so editing a file in the repo changes the live desktop. That's how yurice is developed, and it's how you should read this book: open the file in one window, look at the result in another.

## The quickshell folder

Since most of the book happens here, here's the layout of [`config/quickshell/`](../../config/quickshell):

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

- A **module** uses components and services.
- A **component** only knows the theme, and never talks to the system. The exceptions are three non-visual helpers that services build on: `Poller` runs a command on a timer, `KeyFile` reads and writes a key file, and `SearchFeed` does the paging and downloading shared by the two image searches.
- A **service** never draws anything.

This should explain why a slider can be reused anywhere, and why the audio code doesn't break when the volume panel is redesigned.

## Recap

- niri manages windows and runs commands on keybinds.
- quickshell runs the QML that draws everything else.
- matugen turns the wallpaper into color files that every program reloads.
- They only share files and commands, never code.
