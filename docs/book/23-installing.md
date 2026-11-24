# 23. Installing

Part VI is about getting yurice onto a machine and keeping it working. There are two ways in: [`install.sh`](../../install.sh) for Arch and Debian, and a Nix flake for NixOS and home-manager. They install the same things and put configs in the same places, and this chapter goes through both.

Both follow one rule: your configs are links into the repo, not copies. Editing a file in the repo changes your desktop, and `git pull` updates it. That's why the installer ends with "Keep the repo in place: your configs link into it."

## install.sh

The script is plain POSIX `sh`, about 900 lines, with one function per job. `main` reads almost like the README:

```sh
main() {
  parse_args "$@"
  check_system
  if [ "$uninstall" = 1 ]; then
    uninstall_all
    exit 0
  fi
  choose_components
  has desktop && choose_upscaler
  say "installing:$components from $repo"
  [ "$dry" = 1 ] && say "dry run: nothing will be changed"
  install_packages
  if [ "$distro" = debian ]; then
    has desktop && install_debian_desktop_extras
    has terminal && install_debian_terminal_extras
  fi
  has desktop && install_upscaler
  has desktop && install_desktop
  has terminal && install_terminal
  has greeter && install_greeter
  ...
}
```

[`install.sh:864-890`](../../install.sh#L864-L890)

### Components

There are three components: `desktop` (niri, quickshell, matugen, clipboard history, wallpapers), `terminal` (kitty, fish, starship, tmux, neovim, lazygit, fastfetch, less) and `greeter` (the login screen on greetd). Pass them as arguments, or run the script with none and it asks about each. The greeter needs the desktop, since it's built from the same QML. The terminal is independent of both.

### Checking the system

`check_system` refuses to run as root (it calls `sudo` itself when it needs to, so files in your home stay yours), reads `/etc/os-release`, and accepts Arch and anything based on it, or Debian 13 (trixie) and newer. Anything else gets a clear error, and NixOS gets pointed at the flake.

### Packages

Package lists are plain text files in [`deps/`](../../deps), one per distro and component:

```text
deps/
├── arch/
│   ├── desktop.txt
│   ├── greeter.txt
│   ├── terminal.txt
│   ├── upscaler-build.txt
│   └── upscaler-release.txt
└── debian/
    ├── backports.txt
    ├── desktop-build.txt
    ├── desktop.txt
    ├── greeter.txt
    ├── terminal.txt
    └── upscaler-release.txt
```

`install_packages` joins the lists for the chosen components, removes duplicates, and installs them all in one `pacman -S --needed` or `apt-get install`. Keeping them as files means adding a dependency is a one-line change, and it's easy to see the two distros side by side. [`nix/packages.nix`](../../nix/packages.nix) is the third list. When you add a dependency, all three should change together.

`--no-packages` skips this step, for when you manage packages yourself.

### What Debian doesn't have

Arch packages everything yurice needs. Debian 13 doesn't package niri, xwayland-satellite or matugen at all, quickshell comes from trixie-backports, and its kitty and neovim are too old for the configs. Debian also names some tools differently, so the script links `bat` and `fd` to Debian's `batcat` and `fdfind`. For those, the script builds or downloads pinned upstream versions into `/usr/local`, and the pins are at the top of the file:

```sh
niri_tag=v26.04
niri_rev=8ed0da44d974c32c6877d2f4630c314da0717ecb
...
matugen_url=https://github.com/InioX/matugen/releases/download/v4.2.0/matugen-4.2.0-x86_64.tar.gz
matugen_sha256=a2e3b50e49ed6439999ba3c252ed04fabd98ee4e9d12e5e5dff2e66370569751
nvim_version=v0.12.6
```

[`install.sh:17-25`](../../install.sh#L17-L25)

Every download is checked against a SHA-256, and every source build against a commit:

```sh
fetch() {
  curl -fsSL -o "$3" "$1"
  printf '%s  %s\n' "$2" "$3" | sha256sum -c --quiet || die "checksum mismatch for $1"
}

fetch_source() {
  git clone --quiet --depth 1 --branch "$3" "$2" "$1"
  [ "$(git -C "$1" rev-parse HEAD)" = "$4" ] ||
    die "the upstream $3 tag of $2 no longer points at $4; refusing to build"
}
```

[`install.sh:164-173`](../../install.sh#L164-L173)

A tag on GitHub can be moved to point at different code. Checking that the tag still resolves to the commit that was tested means the build is exactly what was tested, or nothing at all. The same goes for the fonts (Agave Nerd Font, Material Symbols) and the adw-gtk3 theme.

Rust programs are built with `cargo build --release --locked` in `~/.cache/yurice-build`, not in `/tmp`, which on Debian 13 is a small RAM disk that a niri build would fill. Tools that are already installed are skipped.

### The upscaler

`realesrgan-ncnn-vulkan` (chapter 17) is the one dependency with a choice, `--upscaler=`:

- `build` compiles it from a pinned upstream commit against Arch's own `ncnn` and Vulkan libraries. This is the default on Arch.
- `aur` installs `realesrgan-ncnn-vulkan-bin` with paru or yay.
- `release` downloads the prebuilt upstream binary, x86_64 only. This is the default on Debian.
- `none` skips it, and the upscale button won't work.

### Linking configs

Every config goes through `link`:

```sh
link() {
  src=$1
  dst=$2
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    record "link $dst"
    return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    rel=${dst#"$HOME"/}
    run mkdir -p "$(dirname "$backup_dir/$rel")"
    run mv "$dst" "$backup_dir/$rel"
    say "backed up ~/$rel to $backup_dir/$rel"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  record "link $dst"
}
```

[`install.sh:146-162`](../../install.sh#L146-L162)

If the link already exists, nothing happens, so running the script again is safe. If something else is there, your old niri config say, it's moved to `~/.local/state/yurice/backup/<date>/` with its path kept, not deleted.

Besides the links, the desktop step creates `~/.config/yurice/custom/`, installs the cliphist and polkit agent user services, sets the GTK icon theme and hides title bar buttons, copies the bundled wallpapers into `~/Pictures/Wallpapers` (once, and never over your own files), and enables Bluetooth, power profiles and NetworkManager. If another network manager is running, it asks before switching, since the Wi-Fi panel only works with NetworkManager. The terminal step writes `kitty.local.conf` with your fish path (chapter 22) and offers to make fish your login shell.

### Remembering everything

Every change the script makes is written to a manifest, `~/.local/state/yurice/installed`, one line each:

```sh
record() {
  [ "$dry" = 1 ] && return 0
  mkdir -p "$state_dir"
  grep -qxF "$1" "$manifest" 2>/dev/null || printf '%s\n' "$1" >>"$manifest"
}
```

[`install.sh:117-121`](../../install.sh#L117-L121)

Lines look like `link /home/you/.config/niri`, `file …`, `system /usr/local/bin/niri`, `unit yurice-cliphist.service`, `greetd-config` or `previous-dm sddm.service`. Each line is added only once, so running the installer twice doesn't duplicate anything. This is what makes uninstalling exact.

### Dry runs

Every command that changes something goes through `run`, which prints the command instead of running it when `--dry-run` is set. `./install.sh --dry-run desktop terminal` shows exactly what would happen, and nothing is recorded.

### The greeter

`install_greeter` copies the quickshell folder to `/usr/local/share/yurice`, since the greeter user can't read your home. It writes the greeter's niri config and start scripts to `/etc/yurice/`, creates `/var/lib/yurice/users/$USER` for the files your session publishes (chapter 17), and backs up your existing `/etc/greetd/config.toml` before replacing it. If another display manager is enabled, it asks before disabling it, and records which one it was. Chapter 20 covers how the greeter runs.

The greeter is a copy, not a link, so after `git pull` you re-run `./install.sh greeter` to update it.

## Uninstalling

`./install.sh --uninstall` reads the manifest from top to bottom and undoes each line:

```sh
    case $kind in
      link)
        [ -L "$path" ] && run rm "$path"
        restore_backup "$path"
        ;;
      file) [ -f "$path" ] && run rm "$path" ;;
      dir) [ -d "$path" ] && run rm -rf "$path" ;;
      system) { [ -e "$path" ] || [ -L "$path" ]; } && run sudo rm -rf "$path" ;;
      greetd-config)
        if [ -f /etc/greetd/config.toml.yurice-backup ]; then
          run sudo mv /etc/greetd/config.toml.yurice-backup /etc/greetd/config.toml
        fi
        ;;
      previous-dm) run sudo systemctl enable "$path" ;;
    esac
```

[`install.sh:837-851`](../../install.sh#L837-L851)

Links are removed only if they're still links, and the newest backup of each is moved back. Your old greetd config and your old display manager come back. Packages stay installed, since other programs may need them, and the backups folder is kept in case you want something from it. Your `custom/` folder, state and wallpapers aren't in the manifest, so they're never touched.

## Nix

[`flake.nix`](../../flake.nix) exports two modules and nothing else:

```nix
    nixosModules.default = import ./nix/nixos.nix self;
    homeModules.default = import ./nix/home.nix self;
```

[`flake.nix:12-13`](../../flake.nix#L12-L13)

The split follows what needs root. The NixOS module handles the system: niri, PipeWire, UPower, power profiles, Bluetooth, NetworkManager, portals, fonts, Qt and GTK integration, and the greeter. The home-manager module handles your user: packages, config links, cliphist, the polkit agent and dconf settings. The README shows how to wire them into a flake.

### The NixOS module

[`nix/nixos.nix`](../../nix/nixos.nix) has `programs.yurice.enable` and a `greeter` group. Most services are set with `lib.mkDefault`, so your own config wins when you set them differently.

The greeter on NixOS is built entirely in Nix: the quickshell folder is copied into the store, and the start script and niri config are generated from the same templates in [`dist/greeter/`](../../dist/greeter) with their placeholders filled by `builtins.replaceStrings`. greetd runs the result. `greeter.niriExtraConfig` is pasted into the greeter's niri config, which is the place for an `output` block when the login screen comes up at the wrong scale. The `/var/lib/yurice/users/<name>` folders are created for every normal user with `systemd.tmpfiles`.

### The home-manager module

[`nix/home.nix`](../../nix/home.nix) has `desktop.enable`, `terminal.enable` and `configDir`. The interesting one is `configDir`:

```nix
  liveCheckout = builtins.isString cfg.configDir;

  link = rel: {recursive ? false}:
    if liveCheckout
    then {
      source = config.lib.file.mkOutOfStoreSymlink "${cfg.configDir}/${rel}";
      force = true;
    }
    else {
      source = cfg.configDir + "/${rel}";
      inherit recursive;
      force = true;
    };
```

[`nix/home.nix:11-23`](../../nix/home.nix#L11-L23)

By default, `configDir` is a path inside the flake input, so configs are linked from the read-only Nix store, and updating means `nix flake update yurice` and a rebuild. That's the normal Nix way, but it means you can't edit a QML file and see the result.

If you set `configDir` to a string, like `"/home/you/src/yurice/config"`, the module treats it as a live checkout and links with `mkOutOfStoreSymlink`, which points straight at that folder instead of copying it into the store. Now the links work exactly like `install.sh`'s, edits apply as soon as you save, and `git pull` updates you. That's the setup for working on yurice itself.

Directories the programs write into, like `fish` and `nvim`, are linked with `recursive = true` in store mode, so each file is linked separately and the program can still create its own files next to them. `kitty.local.conf` is written with the store path of fish, and it's `mkDefault`, so you can replace it.

The last chapter is how changes are checked before they go in.
