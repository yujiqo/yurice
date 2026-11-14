# Customizing

yurice is built so you never have to fork it, or edit files inside the repo, to make it yours. Every config loads one optional file from `~/.config/yurice/custom/` at the very end. `git pull` never touches that folder, and neither does the installer.

This page lists every one of those hooks, what the shell's `settings.json` holds, where API keys go, and where the shell keeps its state.

## The `custom/` folder

```text
~/.config/yurice/custom/
├── niri/
│   ├── outputs.kdl          # monitor layout. the shell's display settings write this one
│   └── config.kdl           # anything else for niri
├── kitty/kitty.conf
├── fish/config.fish
├── tmux/tmux.conf
├── nvim/init.lua
├── quickshell/settings.json # written by the user island's settings
└── avatars/
    ├── weeb.jpg             # avatar in the first mode
    └── normie.jpg           # avatar in the second mode
```

None of these files have to exist. Create only the ones you need.

| File                       | Loaded by                                                             | How                                          |
| -------------------------- | --------------------------------------------------------------------- | -------------------------------------------- |
| `niri/outputs.kdl`         | [`config/niri/config.kdl`](../config/niri/config.kdl)                 | `include optional=true`, before the next one |
| `niri/config.kdl`          | [`config/niri/config.kdl`](../config/niri/config.kdl)                 | `include optional=true`, last                |
| `kitty/kitty.conf`         | [`config/kitty/kitty.conf`](../config/kitty/kitty.conf)               | `include`, last                              |
| `fish/config.fish`         | [`config/fish/config.fish`](../config/fish/config.fish)               | `source` if it exists, last                  |
| `tmux/tmux.conf`           | [`config/tmux/tmux.conf`](../config/tmux/tmux.conf)                   | `source-file -q`, before plugins load        |
| `nvim/init.lua`            | [`config/nvim/init.lua`](../config/nvim/init.lua)                     | `dofile` if readable, last                   |
| `quickshell/settings.json` | [`services/Settings.qml`](../config/quickshell/services/Settings.qml) | read and watched live                        |
| `avatars/*.jpg`            | [`services/Settings.qml`](../config/quickshell/services/Settings.qml) | default avatar paths                         |

starship and lazygit have no hook. Their configs are tiny, so replace the symlink if you want something different.

### Examples

A different terminal font:

```conf
# ~/.config/yurice/custom/kitty/kitty.conf
font_family JetBrainsMono Nerd Font
font_size 13
```

Your own abbreviations:

```fish
# ~/.config/yurice/custom/fish/config.fish
if status is-interactive
  abbr -a gs "git status"
end
```

Keyboard layout and an extra bind:

```kdl
// ~/.config/yurice/custom/niri/config.kdl
input {
  keyboard {
    xkb {
      layout "us,ru"
      options "grp:win_space_toggle"
    }
  }
}

binds {
  Mod+Return { spawn "kitty"; }
}
```

## The kitty quirk: `kitty.local.conf`

`config/kitty/kitty.conf` includes **two** extra files: `kitty.local.conf` first, then `custom/kitty/kitty.conf`.

`~/.config/kitty/kitty.local.conf` sits next to the symlinked config, not in `custom/`. It holds one line, the path to fish:

```conf
shell /usr/bin/fish
```

That path is different on every system (`/usr/bin/fish`, `/run/current-system/sw/bin/fish`, `/opt/homebrew/bin/fish`), so it can't be in the repo. `install.sh` writes this file only if it doesn't exist yet, and the home-manager module sets it with `mkDefault`. You rarely need to touch it. If kitty opens the wrong shell, this is the file to check.

## `settings.json`

This is the one file the shell writes to. You normally change it through the user island (`Mod+.`), but you can also edit it by hand. The shell watches the file and picks up changes immediately. If the JSON is invalid, the shell logs a warning and uses the defaults.

| Key                   | Default                     | Meaning                                                |
| --------------------- | --------------------------- | ------------------------------------------------------ |
| `wallpaperDirectory`  | `~/Pictures/Wallpapers`     | Wallpaper library                                      |
| `danbooruDirectory`   | `~/Pictures/Danbooru`       | Where danbooru downloads go                            |
| `screenshotDirectory` | `~/Pictures/Screenshots`    | Where screenshots are saved                            |
| `avatar`              | `custom/avatars/weeb.jpg`   | Avatar in the first mode                               |
| `normieAvatar`        | `custom/avatars/normie.jpg` | Avatar in the second mode                              |
| `idleScreenOff`       | `10`                        | Minutes idle before the screens turn off. `0` = never  |
| `idleLock`            | `30`                        | Minutes idle before locking. `0` = never               |
| `idleLockedScreenOff` | `1`                         | Minutes on the lock screen before the screens turn off |
| `idleSuspend`         | `5`                         | Minutes on the lock screen before suspending           |
| `clock24h`            | `true`                      | 24-hour clock                                          |
| `clockSeconds`        | `false`                     | Show seconds                                           |
| `hiddenIslands`       | `[]`                        | Bar islands to hide (see below)                        |
| `weatherLocation`     | auto (by IP)                | `{ "name", "latitude", "longitude" }`                  |
| `weatherFahrenheit`   | `false`                     | °F instead of °C                                       |
| `outputs`             | none                        | Monitor layout from the display settings               |

Paths may start with `~`. Caffeine (`Mod+Shift+B`) pauses all four idle timers.

Island ids for `hiddenIslands`: `media`, `theme`, `wallpapers`, `danbooru`, `weeb`, `weather`, `connectivity`, `levels`, `battery`, `time`.

Display changes apply right away with a countdown, and go back to the old layout unless you press keep. When you keep a layout, the shell saves it to `outputs` and writes `custom/niri/outputs.kdl`, so niri uses it from the next login on. If you'd rather write output config by hand, put it in `custom/niri/config.kdl` and leave the display settings alone, otherwise the two will fight.

## The two modes

Mode settings live in the shell's state, not in `settings.json`, and you change them in the mode panel (`Mod+S`):

- **Names.** The two modes are called "Weeb" and "Normie" until you rename them (16 characters max).
- **What the second mode hides.** By default it hides all of these:
  - the first-mode avatar, replaced with `normieAvatar`
  - wallpapers you haven't marked as safe. The second mode also remembers its own wallpaper.
  - the danbooru island
  - the anime and adult filters in wallpaper search
  - any other bar islands you pick

`Mod+Shift+S` flips between the modes.

## API keys

Keys live in plain text files in `~/.config/yurice/`, outside `custom/`, the shell writes the file with `umask 077`. If you create one by hand, make sure to run `chmod 600` on it.

| Service   | File                             | Format                            |
| --------- | -------------------------------- | --------------------------------- |
| danbooru  | `~/.config/yurice/danbooru.key`  | line 1: username, line 2: API key |
| wallhaven | `~/.config/yurice/wallhaven.key` | line 1: API key                   |

- **danbooru:** create the key on your danbooru profile page, here you can choose which permissions to allow. I recommend you to set only these permissions:
  - `counts:posts`, for counting results so pages can be picked
  - `posts:index`, for searching posts
  - `users:profile`, for reading your account's tag limit
- **wallhaven:** optional. Without a key, every search is SFW only. With a key, the rest of wallhaven's content becomes available, but only in the first mode.
- **weather:** uses [open-meteo](https://open-meteo.com) and needs no key. If you don't set a location, it guesses one from your IP through ipinfo.io.

## Where things live

| Path                              | What                                                                               | Safe to delete?                  |
| --------------------------------- | ---------------------------------------------------------------------------------- | -------------------------------- |
| `~/.config/yurice/custom/`        | your overrides and `settings.json`                                                 | yes, the shell uses default then |
| `~/.config/yurice/*.key`          | API keys                                                                           | yes, re-enter                    |
| `~/.local/state/yurice/`          | what the shell remembers: wallpaper, theme, mode, launcher history, search filters | yes, resets                      |
| `~/.local/state/yurice/installed` | `install.sh`'s log, used by `--uninstall`                                          | **no**                           |
| `~/.local/state/yurice/backup/`   | files `install.sh` replaced                                                        | after uninstall                  |
| `~/.cache/yurice/`                | generated colors, thumbnails                                                       | yes, rebuilt                     |
| `/var/lib/yurice/`                | the greeter's copy of each user's wallpaper, avatar and colors                     | rebuilt on login                 |

`$YURICE_STATE_ROOT` overrides `/var/lib/yurice`.

## The greeter

The greeter runs its own small niri session, so your `custom/niri/` files don't reach it. To set output scaling or other niri settings for the login screen:

- **Arch / Debian:** write it to `/etc/yurice/greeter-local.kdl`. The greeter's niri config includes that file if it exists.
- **NixOS:** use the option:

  ```nix
  programs.yurice.greeter.niriExtraConfig = ''
    output "eDP-1" { scale 1.25; }
  '';
  ```

The greeter shows each user's last wallpaper and avatar. The shell publishes them to `/var/lib/yurice/users/<you>/` whenever they change.
