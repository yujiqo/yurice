#!/bin/sh
set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/yurice
manifest=$state_dir/installed
backup_dir=$state_dir/backup/$(date +%Y%m%d-%H%M%S)
greeter_share=/usr/local/share/yurice
upscaler_prefix=/usr/local
upscaler_rev=37026f49824c5cf84062e7c6a5dd71445dcf610f
models_url=https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesrgan-ncnn-vulkan-20220424-ubuntu.zip
models_sha256=e5aa6eb131234b87c0c51f82b89390f5e3e642b7b70f2b9bbe95b6a285a40c96

dry=0
packages=1
assume_yes=0
uninstall=0
components=""
upscaler=build

usage() {
  cat <<EOF
Usage: ./install.sh [components] [options]

Components (prompted for when none are given):
  desktop     niri, quickshell, matugen theming, clipboard history, wallpapers
  terminal    kitty, fish, starship, tmux, neovim, lazygit, fastfetch, less
  greeter     the quickshell login screen on greetd (needs desktop, uses sudo)

Options:
  --dry-run       print what would be done without changing anything
  --no-packages   skip installing packages
  --upscaler=MODE how to get the wallpaper upscaler (desktop only):
                    build  compile it from upstream source with official
                           repo libraries (default)
                    aur    install realesrgan-ncnn-vulkan-bin with paru/yay
                    none   skip it; wallpaper upscaling will not work
  -y, --yes       answer yes to every question
  --uninstall     remove the links, files and units this script created
  -h, --help      show this help
EOF
}

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}

run() {
  if [ "$dry" = 1 ]; then
    printf '  + %s\n' "$*"
  else
    "$@"
  fi
}

ask() {
  [ "$assume_yes" = 1 ] && return 0
  printf '%s [y/N] ' "$1"
  read -r reply </dev/tty 2>/dev/null || reply=n
  case $reply in
    [yY]*) return 0 ;;
    *) return 1 ;;
  esac
}

has() {
  case " $components " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

record() {
  [ "$dry" = 1 ] && return 0
  mkdir -p "$state_dir"
  grep -qxF "$1" "$manifest" 2>/dev/null || printf '%s\n' "$1" >>"$manifest"
}

write_user() {
  if [ "$dry" = 1 ]; then
    printf '  + write %s\n' "$1"
    cat >/dev/null
    return 0
  fi
  mkdir -p "$(dirname "$1")"
  cat >"$1"
  record "file $1"
}

write_system() {
  if [ "$dry" = 1 ]; then
    printf '  + sudo write %s\n' "$1"
    cat >/dev/null
    return 0
  fi
  sudo install -d "$(dirname "$1")"
  sudo tee "$1" >/dev/null
  sudo chmod "$2" "$1"
  record "system $1"
}

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

parse_args() {
  for arg in "$@"; do
    case $arg in
      desktop | terminal | greeter) components="$components $arg" ;;
      --dry-run) dry=1 ;;
      --no-packages) packages=0 ;;
      --upscaler=build | --upscaler=aur | --upscaler=none) upscaler=${arg#--upscaler=} ;;
      -y | --yes) assume_yes=1 ;;
      --uninstall) uninstall=1 ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        die "unknown argument: $arg"
        ;;
    esac
  done
}

check_system() {
  [ "$(id -u)" -ne 0 ] || die "run this as your own user; it calls sudo when it needs to"
  [ -r /etc/os-release ] || die "cannot read /etc/os-release"
  ID="" ID_LIKE=""
  . /etc/os-release
  case " $ID $ID_LIKE " in
    *" arch "*) ;;
    *) die "install.sh supports Arch Linux only. On NixOS, use the flake modules instead." ;;
  esac
}

choose_components() {
  if [ -z "$components" ]; then
    ask "Install the desktop (niri + quickshell)?" && components="$components desktop"
    ask "Install the terminal setup (kitty, fish, neovim, ...)?" && components="$components terminal"
    has desktop && ask "Install the greeter (replaces your display manager)?" && components="$components greeter"
  fi
  [ -n "$components" ] || die "nothing to install"
  if has greeter && ! has desktop; then
    die "the greeter needs the desktop component"
  fi
}

package_list() {
  [ -f "$repo/deps/arch/$1.txt" ] || return 0
  grep -v '^[[:space:]]*$' "$repo/deps/arch/$1.txt"
}

install_packages() {
  [ "$packages" = 1 ] || return 0
  official=""
  for c in $components; do
    official="$official $(package_list "$c")"
  done
  if has desktop && [ "$upscaler" = build ]; then
    official="$official $(package_list upscaler-build)"
  fi
  official=$(printf '%s\n' $official | sort -u | tr '\n' ' ')

  say "installing packages from the official repositories"
  run sudo pacman -S --needed $official
}

install_upscaler() {
  if [ "$upscaler" != none ] && ! ls /usr/share/vulkan/icd.d/*.json >/dev/null 2>&1; then
    warn "no Vulkan driver found; the upscaler needs one (vulkan-intel, vulkan-radeon or nvidia-utils)"
  fi
  case $upscaler in
    none)
      say "skipping the wallpaper upscaler"
      return 0
      ;;
    aur) install_upscaler_from_aur ;;
    build) build_upscaler ;;
  esac
}

install_upscaler_from_aur() {
  aur=realesrgan-ncnn-vulkan-bin
  helper=""
  for candidate in paru yay; do
    if command -v "$candidate" >/dev/null 2>&1; then
      helper=$candidate
      break
    fi
  done
  if [ -z "$helper" ]; then
    die "--upscaler=aur needs an AUR helper (paru or yay). Install one, or use --upscaler=build"
  fi
  say "installing $aur from the AUR with $helper"
  run "$helper" -S --needed "$aur"
}

build_upscaler() (
  bin=$upscaler_prefix/bin/realesrgan-ncnn-vulkan
  models=$upscaler_prefix/share/realesrgan-ncnn-vulkan/models
  if command -v realesrgan-ncnn-vulkan >/dev/null 2>&1; then
    say "wallpaper upscaler already installed at $(command -v realesrgan-ncnn-vulkan)"
    exit 0
  fi
  say "building the wallpaper upscaler from source"
  if [ "$dry" = 1 ]; then
    printf '  + build Real-ESRGAN-ncnn-vulkan %s into %s\n' "$upscaler_rev" "$bin"
    printf '  + fetch models from %s (sha256 %s) into %s\n' "$models_url" "$models_sha256" "$models"
    exit 0
  fi

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  git clone --quiet --depth 1 --branch v0.2.0 https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan "$work/src"
  [ "$(git -C "$work/src" rev-parse HEAD)" = "$upscaler_rev" ] ||
    die "the upstream v0.2.0 tag no longer points at $upscaler_rev; refusing to build"
  git -C "$work/src" apply --directory=src "$repo/dist/upscaler/cmakelists.patch" "$repo/dist/upscaler/models_path.patch"
  sed -i "s|REPLACE_MODELS|$models|" "$work/src/src/main.cpp"
  cmake -S "$work/src/src" -B "$work/build" -Wno-dev \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_SYSTEM_NCNN=1 \
    -DUSE_SYSTEM_WEBP=1 \
    -DGLSLANG_TARGET_DIR=/usr/lib/cmake/glslang
  cmake --build "$work/build" -j "$(nproc)"

  curl -fsSL -o "$work/models.zip" "$models_url"
  printf '%s  %s\n' "$models_sha256" "$work/models.zip" | sha256sum -c --quiet ||
    die "checksum mismatch for $models_url"
  unzip -q "$work/models.zip" 'models/realesr-animevideov3-*' -d "$work"

  sudo install -Dm755 "$work/build/realesrgan-ncnn-vulkan" "$bin"
  sudo install -d "$models"
  sudo install -m644 "$work"/models/realesr-animevideov3-* "$models/"
  record "system $bin"
  record "system $upscaler_prefix/share/realesrgan-ncnn-vulkan"
)

enable_system_service() {
  if systemctl is-enabled -q "$1" 2>/dev/null; then
    return 0
  fi
  run sudo systemctl enable "$1"
}

install_desktop() {
  say "linking desktop configs"
  link "$repo/config/niri" "$config_home/niri"
  link "$repo/config/quickshell" "$config_home/quickshell"
  link "$repo/config/matugen" "$config_home/matugen"
  link "$repo/dist/gtk/settings.ini" "$config_home/gtk-3.0/settings.ini"
  link "$repo/dist/gtk/settings.ini" "$config_home/gtk-4.0/settings.ini"
  run mkdir -p "$config_home/yurice/custom"

  sed "s|@cmark@|$(command -v cmark-gfm || echo /usr/bin/cmark-gfm)|" "$repo/dist/sushi-markdown.js" |
    write_user "$data_home/sushi/viewers/markdown.js"
  printf 'QT_WAYLAND_DISABLE_WINDOWDECORATION=1\n' | write_user "$config_home/environment.d/yurice.conf"

  say "enabling clipboard history"
  for unit in yurice-cliphist.service yurice-cliphist-images.service; do
    link "$repo/dist/systemd/$unit" "$config_home/systemd/user/$unit"
    record "unit $unit"
  done
  run systemctl --user daemon-reload || warn "could not reach the systemd user manager"
  run systemctl --user enable yurice-cliphist.service yurice-cliphist-images.service ||
    warn "enable the clipboard units later with: systemctl --user enable yurice-cliphist.service yurice-cliphist-images.service"

  run gsettings set org.gnome.desktop.interface icon-theme Adwaita ||
    warn "could not set the icon theme; run it again from inside your session"
  run gsettings set org.gnome.desktop.wm.preferences button-layout ':' ||
    warn "could not set the titlebar button layout; run it again from inside your session"

  say "copying bundled wallpapers"
  run sh "$repo/dist/seed-wallpapers.sh" "$repo/wallpapers"

  say "enabling system services"
  enable_system_service bluetooth.service
  enable_system_service power-profiles-daemon.service
  if ! systemctl is-enabled -q NetworkManager.service 2>/dev/null; then
    others=""
    for other in systemd-networkd.service iwd.service connman.service dhcpcd.service; do
      systemctl is-enabled -q "$other" 2>/dev/null && others="$others $other"
    done
    if [ -n "$others" ]; then
      warn "the wifi panel needs NetworkManager, but these are enabled:$others"
      if ask "Disable them and enable NetworkManager?"; then
        run sudo systemctl disable $others
        run sudo systemctl enable NetworkManager.service
      fi
    else
      run sudo systemctl enable NetworkManager.service
    fi
  fi
}

install_terminal() {
  say "linking terminal configs"
  link "$repo/config/kitty/kitty.conf" "$config_home/kitty/kitty.conf"
  link "$repo/config/kitty/current-theme.conf" "$config_home/kitty/current-theme.conf"
  if [ ! -e "$config_home/kitty/kitty.local.conf" ]; then
    printf 'shell %s\n' "$(command -v fish || echo /usr/bin/fish)" | write_user "$config_home/kitty/kitty.local.conf"
  fi
  link "$repo/config/fish" "$config_home/fish"
  link "$repo/config/starship/starship.toml" "$config_home/starship.toml"
  link "$repo/config/tmux" "$config_home/tmux"
  link "$repo/config/nvim" "$config_home/nvim"
  link "$repo/config/lazygit" "$config_home/lazygit"
  link "$repo/config/fastfetch" "$config_home/fastfetch"
  link "$repo/config/less/key" "$HOME/.lesskey"

  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    say "installing the tmux plugin manager"
    run git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    record "dir $HOME/.tmux/plugins/tpm"
  fi

  fish=$(command -v fish || echo /usr/bin/fish)
  if [ "$(getent passwd "$(id -un)" | cut -d: -f7)" != "$fish" ] && ask "Make fish your login shell?"; then
    run chsh -s "$fish"
  fi
}

install_greeter() {
  say "installing the greeter (sudo)"
  run sudo rm -rf "$greeter_share/quickshell"
  run sudo install -d "$greeter_share"
  run sudo cp -r "$repo/config/quickshell" "$greeter_share/quickshell"
  record "system $greeter_share"

  sed "s|@greeterQml@|$greeter_share/quickshell/greeter.qml|" "$repo/dist/greeter/start.sh" |
    write_system /etc/yurice/greeter-start.sh 755
  sed -e "s|@greeterStart@|/etc/yurice/greeter-start.sh|" \
    -e 's|@extraConfig@|include optional=true "/etc/yurice/greeter-local.kdl"|' \
    "$repo/dist/greeter/niri.kdl" | write_system /etc/yurice/greeter-niri.kdl 644
  write_system /etc/yurice/greeter-session.sh 755 <<'EOF'
#!/bin/sh
export HOME=/var/lib/yurice/greeter
exec niri -c /etc/yurice/greeter-niri.kdl >/dev/null 2>&1
EOF
  write_system /etc/yurice/hide-console.sh 755 <"$repo/dist/greeter/hide-console.sh"
  printf '[Service]\nExecStartPre=-/etc/yurice/hide-console.sh\n' |
    write_system /etc/systemd/system/greetd.service.d/yurice.conf 644
  record "system /etc/yurice"

  write_system /etc/tmpfiles.d/yurice.conf 644 <<EOF
d /var/lib/yurice 0755 root root -
d /var/lib/yurice/greeter 0755 greeter greeter -
d /var/lib/yurice/users 0755 root root -
d /var/lib/yurice/users/$(id -un) 0755 $(id -un) $(id -gn) -
EOF
  run sudo systemd-tmpfiles --create /etc/tmpfiles.d/yurice.conf

  if [ -f /etc/greetd/config.toml ] && ! grep -q yurice /etc/greetd/config.toml; then
    run sudo cp /etc/greetd/config.toml /etc/greetd/config.toml.yurice-backup
  fi
  write_system /etc/greetd/config.toml 644 <<'EOF'
[terminal]
vt = 1

[default_session]
command = "/etc/yurice/greeter-session.sh"
user = "greeter"
EOF
  record "greetd-config"

  run sudo systemctl daemon-reload
  current=$(basename "$(readlink /etc/systemd/system/display-manager.service 2>/dev/null)" 2>/dev/null || true)
  if [ -n "$current" ] && [ "$current" != greetd.service ]; then
    if ask "Disable $current and use greetd instead?"; then
      run sudo systemctl disable "$current"
      record "previous-dm $current"
    else
      warn "greetd was not enabled; $current stays your display manager"
      return 0
    fi
  fi
  run sudo systemctl enable greetd.service
  record "greetd-enabled"
}

restore_backup() {
  rel=${1#"$HOME"/}
  saved=""
  for stamp in "$state_dir"/backup/*; do
    if [ -e "$stamp/$rel" ] || [ -L "$stamp/$rel" ]; then
      saved=$stamp/$rel
    fi
  done
  [ -n "$saved" ] || return 0
  if [ -e "$1" ] || [ -L "$1" ]; then
    return 0
  fi
  run mv "$saved" "$1"
  say "restored ~/$rel"
}

uninstall_all() {
  [ -f "$manifest" ] || die "nothing to uninstall: $manifest does not exist"
  say "removing what install.sh created"
  units=$(sed -n 's/^unit //p' "$manifest")
  if [ -n "$units" ]; then
    run systemctl --user disable $units || true
  fi
  if grep -qx greetd-enabled "$manifest"; then
    run sudo systemctl disable greetd.service
  fi
  while IFS= read -r entry; do
    kind=${entry%% *}
    path=${entry#* }
    case $kind in
      link)
        [ -L "$path" ] && run rm "$path"
        restore_backup "$path"
        ;;
      file) [ -f "$path" ] && run rm "$path" ;;
      dir) [ -d "$path" ] && run rm -rf "$path" ;;
      system) [ -e "$path" ] && run sudo rm -rf "$path" ;;
      greetd-config)
        if [ -f /etc/greetd/config.toml.yurice-backup ]; then
          run sudo mv /etc/greetd/config.toml.yurice-backup /etc/greetd/config.toml
        fi
        ;;
      previous-dm) run sudo systemctl enable "$path" ;;
    esac
  done <"$manifest"
  run systemctl --user daemon-reload || true
  if grep -q '^system ' "$manifest"; then
    run sudo systemctl daemon-reload
  fi
  run rm "$manifest"
  say "done. Packages were left installed, and backups stay in $state_dir/backup"
}

main() {
  parse_args "$@"
  check_system
  if [ "$uninstall" = 1 ]; then
    uninstall_all
    exit 0
  fi
  choose_components
  say "installing:$components from $repo"
  [ "$dry" = 1 ] && say "dry run: nothing will be changed"
  install_packages
  has desktop && install_upscaler
  has desktop && install_desktop
  has terminal && install_terminal
  has greeter && install_greeter
  say "done. Keep $repo in place: your configs link into it."
  if has greeter; then
    say "reboot to get the greeter"
  elif has desktop; then
    say "log out and start niri (niri-session) to get the desktop"
  fi
}

main "$@"
