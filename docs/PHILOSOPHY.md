# Philosophy

yurice is my personal desktop that grew up enough to be shared.

## Keyboard first, mouse welcome

The fastest way to use a computer is not to leave the home row, so everything in yurice can be reached and used without a mouse.

- Every panel in the bar opens from a keybind, and you move inside it with `h` `j` `k` `l` or the arrow keys, `Tab` / `Shift+Tab`, `Enter` / `Space`, and `Esc`.
- The keybind cheatsheet (`Mod+Shift+/`) is read straight from the niri config, so it can't fall out of date.
- The focus ring only appears once you actually start using the keyboard.

Hover, click, and scroll with mouse/trackpad, all work as well.

> When you add something, ask: _can I open it, use it, and close it without touching the mouse?_

## Borrow the best

Other systems already solved a lot of small problems well, and I want to bring best out of all of them.

- The launcher is opened with `Alt+Space` and has a built-in calculator, like Spotlight on macOS.
- Clipboard history is one keybind away, like `Win+V` on Windows.
- The status bar that utilizes dynamic island idea and the panels grew out of time spent using and looking on other Linux rices (end-4's dots, iNiR, DankMaterialShell, Noctalia).

## One wallpaper, one theme

You pick a wallpaper and the whole desktop follows it. matugen turns the wallpaper into a Material You palette, and that palette is used by:

- the shell
- kitty
- niri
- neovim
- tmux
- fastfetch

Light and dark mode come from the same palette, and can switch on a schedule.

So there is no theme to maintain by hand, and the theme is consistent across the system, which brings us closer to the next point.

## Consistency over cleverness

A small rice feels polished when everything is consistent. The rules that follow from that:

- **Tokens, not numbers.** Sizes, radii, durations, and colors live in `Theme.qml`.
- **Components, not copies.** If two panels need the same row, it becomes one component in `components/`.
- **Same problem, same solution.** Wallpaper search and danbooru search share `SearchFeed`. Wifi and bluetooth use the same panel shape.

## Motion is part of the design

Animations are not decoration on top. I wanted them to give feedback to the user.

- Most motion runs on a single damped spring (`Spring.qml`). Things can be interrupted halfway and still feel physical.
- Shell animations are timed to niri's own animation settings (the same `1.7` slowdown), so the compositor and the shell move like one thing.
- A flash, a jump, or a stutter counts as a bug, and gets fixed like one.

## Your config stays yours

You should never need to fork yurice to make it yours, and updating should never wipe out your changes.

- Every config loads an optional override from `~/.config/yurice/custom/` at the end: niri, kitty, fish, tmux, nvim, and the shell's `settings.json`. The repo stays clean, and `git pull` just works.
- Things live in different places depending on what they are:
  - settings you choose go in `custom/`
  - state the shell remembers goes in `~/.local/state/yurice`
  - throwaway data goes in `~/.cache/yurice`
  - secrets go in their own key files

  Each kind can be backed up, reset, or deleted on its own.

- You can rename and customize the two modes. "weeb" and "normie" are only the defaults.

## Light enough for weak hardware

A pretty desktop that stutters on a five-year-old laptop isn't pretty. Some of the rules that come from this:

- Panels load their content only when opened.
- Wifi and bluetooth scans wait until the open animation has finished.
- The wallpaper picker was tuned for low-end devices early on.
- Slow startup gets treated as a bug too ("fix long startup").

The rice was developed and tested on a Thinkpad L14 Gen 4, which is not a speed demon. I also swapped the only 8gb ram stick to 2x16gb sticks recently, and it didn't change anything except the amount of apps i can leave open at the same time.

More detailed specs of the Thinkpad, if you're interested:

- intel core i5 1345u
- intel iris xe graphics
- 32gb ram (2 sticks)
- 256gb storage
