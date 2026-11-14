#!/bin/sh
set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/yurice
manifest=$state_dir/installed
backup_dir=$state_dir/backup/$(date +%Y%m%d-%H%M%S)
greeter_share=/usr/local/share/yurice
prefix=/usr/local
upscaler_rev=37026f49824c5cf84062e7c6a5dd71445dcf610f
upscaler_url=https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesrgan-ncnn-vulkan-20220424-ubuntu.zip
upscaler_sha256=e5aa6eb131234b87c0c51f82b89390f5e3e642b7b70f2b9bbe95b6a285a40c96

niri_tag=v26.04
niri_rev=8ed0da44d974c32c6877d2f4630c314da0717ecb
satellite_tag=v0.8.3
satellite_rev=b83eab900644e4c7c77982ce3d44cb490f0c5e1d
matugen_tag=v4.2.0
matugen_rev=bb27a35d7f9e0f57cf638703f3d8e3182aed0304
nvim_version=v0.12.6
nvim_sha256_x86_64=474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87
nvim_sha256_arm64=8f1f64a0bdb97247034038c3823c6cbad5bdf9ecd5751b85494b71c3ee04c815
agave_url=https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/Agave.tar.xz
agave_sha256=0b29420ed47a4cc9bc2743d454ef17ea645ae31e6c348e86154d994b6ccc756e
symbols_url='https://raw.githubusercontent.com/google/material-design-icons/10ecc14790612ca8fd164e3f4ffe9c16fc50d5b7/variablefont/MaterialSymbolsSharp%5BFILL,GRAD,opsz,wght%5D.ttf'
symbols_sha256=1fd72f99ec1f44ec461c74f99341c1dcfa8c140d7087a2902e747d4ee01e379b
adw_url=https://github.com/lassekongo83/adw-gtk3/releases/download/v6.5/adw-gtk3v6.5.tar.xz
adw_sha256=a81780fadfc432be0fc3d89c4ebb41aa28e4f032d42c36f9789c57dd10cfa41c

dry=0
packages=1
assume_yes=0
uninstall=0
components=""
upscaler=""
distro=""
codename=""
backports=""

usage() {
  cat <<EOF
Usage: ./install.sh [components] [options]

Supports Arch Linux and Debian 13 (trixie) or newer.

Components (prompted for when none are given):
  desktop     niri, quickshell, matugen theming, clipboard history, wallpapers
  terminal    kitty, fish, starship, tmux, neovim, lazygit, fastfetch, less
  greeter     the quickshell login screen on greetd (needs desktop, uses sudo)

Options:
  --dry-run       print what would be done without changing anything
  --no-packages   skip installing packages from the distro repositories
  --upscaler=MODE how to get the wallpaper upscaler (desktop only):
                    build    compile it from upstream source with official
                             repo libraries (Arch only, default there)
                    aur      install realesrgan-ncnn-vulkan-bin with paru/yay
                             (Arch only)
                    release  install the prebuilt upstream binary (x86_64
                             only, default on Debian)
                    none     skip it; wallpaper upscaling will not work
  -y, --yes       answer yes to every question
  --uninstall     remove the links, files and units this script created
  -h, --help      show this help

On Debian, niri, xwayland-satellite and matugen are built from pinned
upstream sources, and the fonts and the adw-gtk3 theme are fetched from
their upstream releases, all into $prefix.
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

fetch() {
  curl -fsSL -o "$3" "$1"
  printf '%s  %s\n' "$2" "$3" | sha256sum -c --quiet || die "checksum mismatch for $1"
}

fetch_source() {
  git clone --quiet --depth 1 --branch "$3" "$2" "$1"
  [ "$(git -C "$1" rev-parse HEAD)" = "$4" ] ||
    die "the upstream $3 tag of $2 no longer points at $4; refusing to build"
}

install_system() {
  sudo install -D -m "$1" "$2" "$3"
  record "system $3"
}

parse_args() {
  for arg in "$@"; do
    case $arg in
      desktop | terminal | greeter) components="$components $arg" ;;
      --dry-run) dry=1 ;;
      --no-packages) packages=0 ;;
      --upscaler=build | --upscaler=aur | --upscaler=release | --upscaler=none) upscaler=${arg#--upscaler=} ;;
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
  ID="" ID_LIKE="" VERSION_CODENAME=""
  . /etc/os-release
  codename=$VERSION_CODENAME
  if [ "$ID" = debian ]; then
    distro=debian
    case $codename in
      buster | bullseye | bookworm) die "install.sh needs Debian 13 (trixie) or newer" ;;
      trixie) backports=trixie-backports ;;
    esac
  else
    case " $ID $ID_LIKE " in
      *" arch "*) distro=arch ;;
      *) die "install.sh supports Arch Linux and Debian only. On NixOS, use the flake modules instead." ;;
    esac
  fi
}

choose_upscaler() {
  if [ -z "$upscaler" ]; then
    case $distro in
      arch) upscaler=build ;;
      debian)
        if [ "$(uname -m)" = x86_64 ]; then
          upscaler=release
        else
          warn "there is no prebuilt upscaler for $(uname -m); wallpaper upscaling will not work"
          upscaler=none
        fi
        ;;
    esac
  fi
  case $distro:$upscaler in
    debian:build | debian:aur) die "--upscaler=$upscaler is Arch only; use --upscaler=release or --upscaler=none" ;;
  esac
  if [ "$upscaler" = release ] && [ "$(uname -m)" != x86_64 ]; then
    die "the prebuilt upscaler is x86_64 only; use --upscaler=none"
  fi
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
  [ -f "$repo/deps/$distro/$1.txt" ] || return 0
  grep -v '^[[:space:]]*$' "$repo/deps/$distro/$1.txt"
}

install_packages() {
  [ "$packages" = 1 ] || return 0
  lists=$components
  if has desktop; then
    lists="$lists upscaler-$upscaler"
    [ "$distro" = debian ] && lists="$lists desktop-build"
  fi
  official=$(for list in $lists; do package_list "$list"; done | sort -u | tr '\n' ' ')

  case $distro in
    arch)
      say "installing packages from the official repositories"
      run sudo pacman -S --needed $official
      ;;
    debian) install_debian_packages ;;
  esac
}

install_debian_packages() {
  has desktop && [ -n "$backports" ] && enable_backports
  say "refreshing the package index"
  run sudo apt-get update
  say "installing packages from the Debian repositories"
  run sudo apt-get install $official

  if has desktop; then
    backported=$(package_list backports | tr '\n' ' ')
    if [ -n "$backports" ]; then
      run sudo apt-get install -t "$backports" $backported
    else
      run sudo apt-get install $backported
    fi
  fi

  if has terminal; then
    candidate=$(apt-cache policy neovim 2>/dev/null | sed -n 's/^ *Candidate: //p')
    if [ -n "$candidate" ] && [ "$candidate" != "(none)" ] && dpkg --compare-versions "$candidate" ge 0.11; then
      run sudo apt-get install neovim
    else
      install_neovim_release
    fi
  fi
}

enable_backports() {
  if grep -rqsE "^[^#]*$backports" /etc/apt/sources.list /etc/apt/sources.list.d/; then
    return 0
  fi
  warn "quickshell is only in $backports on Debian $codename, which is not enabled"
  ask "Enable $backports?" || die "the desktop needs quickshell from $backports"
  write_system /etc/apt/sources.list.d/yurice-backports.sources 644 <<EOF
Types: deb
URIs: http://deb.debian.org/debian
Suites: $backports
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
}

install_neovim_release() (
  case $(uname -m) in
    x86_64) arch=x86_64 sha=$nvim_sha256_x86_64 ;;
    aarch64) arch=arm64 sha=$nvim_sha256_arm64 ;;
    *) die "Debian's neovim is too old for the config and there is no upstream build for $(uname -m)" ;;
  esac
  dir=$prefix/lib/yurice-nvim
  say "installing neovim $nvim_version from upstream (Debian's is older than 0.11)"
  if [ "$dry" = 1 ]; then
    printf '  + fetch neovim %s for %s into %s\n' "$nvim_version" "$arch" "$dir"
    exit 0
  fi
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  fetch "https://github.com/neovim/neovim/releases/download/$nvim_version/nvim-linux-$arch.tar.gz" "$sha" "$work/nvim.tar.gz"
  tar -xzf "$work/nvim.tar.gz" -C "$work"
  sudo rm -rf "$dir"
  sudo mkdir -p "$prefix/bin"
  sudo cp -r "$work/nvim-linux-$arch" "$dir"
  sudo ln -sfn "$dir/bin/nvim" "$prefix/bin/nvim"
  record "system $dir"
  record "system $prefix/bin/nvim"
)

install_upscaler() {
  if [ "$upscaler" != none ] && ! ls /usr/share/vulkan/icd.d/*.json >/dev/null 2>&1; then
    case $distro in
      arch) warn "no Vulkan driver found; the upscaler needs one (vulkan-intel, vulkan-radeon or nvidia-utils)" ;;
      debian) warn "no Vulkan driver found; the upscaler needs one (mesa-vulkan-drivers or nvidia-vulkan-icd)" ;;
    esac
  fi
  case $upscaler in
    none)
      say "skipping the wallpaper upscaler"
      return 0
      ;;
    aur) install_upscaler_from_aur ;;
    build) build_upscaler ;;
    release) install_upscaler_release ;;
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
  bin=$prefix/bin/realesrgan-ncnn-vulkan
  models=$prefix/share/realesrgan-ncnn-vulkan/models
  if command -v realesrgan-ncnn-vulkan >/dev/null 2>&1; then
    say "wallpaper upscaler already installed at $(command -v realesrgan-ncnn-vulkan)"
    exit 0
  fi
  say "building the wallpaper upscaler from source"
  if [ "$dry" = 1 ]; then
    printf '  + build Real-ESRGAN-ncnn-vulkan %s into %s\n' "$upscaler_rev" "$bin"
    printf '  + fetch models from %s (sha256 %s) into %s\n' "$upscaler_url" "$upscaler_sha256" "$models"
    exit 0
  fi

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  fetch_source "$work/src" https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan v0.2.0 "$upscaler_rev"
  git -C "$work/src" apply --directory=src "$repo/dist/upscaler/cmakelists.patch" "$repo/dist/upscaler/models_path.patch"
  sed -i "s|REPLACE_MODELS|$models|" "$work/src/src/main.cpp"
  cmake -S "$work/src/src" -B "$work/build" -Wno-dev \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_SYSTEM_NCNN=1 \
    -DUSE_SYSTEM_WEBP=1 \
    -DGLSLANG_TARGET_DIR=/usr/lib/cmake/glslang
  cmake --build "$work/build" -j "$(nproc)"

  fetch "$upscaler_url" "$upscaler_sha256" "$work/models.zip"
  unzip -q "$work/models.zip" 'models/realesr-animevideov3-*' -d "$work"

  sudo install -Dm755 "$work/build/realesrgan-ncnn-vulkan" "$bin"
  sudo install -d "$models"
  sudo install -m644 "$work"/models/realesr-animevideov3-* "$models/"
  record "system $bin"
  record "system $prefix/share/realesrgan-ncnn-vulkan"
)

install_upscaler_release() (
  dir=$prefix/lib/realesrgan-ncnn-vulkan
  if command -v realesrgan-ncnn-vulkan >/dev/null 2>&1; then
    say "wallpaper upscaler already installed at $(command -v realesrgan-ncnn-vulkan)"
    exit 0
  fi
  say "installing the prebuilt wallpaper upscaler"
  if [ "$dry" = 1 ]; then
    printf '  + fetch %s (sha256 %s) into %s\n' "$upscaler_url" "$upscaler_sha256" "$dir"
    exit 0
  fi

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  fetch "$upscaler_url" "$upscaler_sha256" "$work/upscaler.zip"
  unzip -q "$work/upscaler.zip" realesrgan-ncnn-vulkan 'models/realesr-animevideov3-*' -d "$work"

  sudo install -Dm755 "$work/realesrgan-ncnn-vulkan" "$dir/realesrgan-ncnn-vulkan"
  sudo install -d "$dir/models"
  sudo install -m644 "$work"/models/realesr-animevideov3-* "$dir/models/"
  sudo mkdir -p "$prefix/bin"
  sudo ln -sfn "$dir/realesrgan-ncnn-vulkan" "$prefix/bin/realesrgan-ncnn-vulkan"
  record "system $dir"
  record "system $prefix/bin/realesrgan-ncnn-vulkan"
)

cargo_build() {
  CARGO_HOME="$1/cargo" cargo build --release --locked \
    --manifest-path "$1/src/Cargo.toml" --target-dir "$1/target"
}

build_niri() (
  if command -v niri >/dev/null 2>&1; then
    say "niri already installed at $(command -v niri)"
    exit 0
  fi
  say "building niri $niri_tag from source (this takes a while)"
  if [ "$dry" = 1 ]; then
    printf '  + build niri %s into %s\n' "$niri_rev" "$prefix"
    exit 0
  fi
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  fetch_source "$work/src" https://github.com/niri-wm/niri "$niri_tag" "$niri_rev"
  cargo_build "$work"
  res=$work/src/resources
  install_system 755 "$work/target/release/niri" "$prefix/bin/niri"
  install_system 755 "$res/niri-session" "$prefix/bin/niri-session"
  install_system 644 "$res/niri.desktop" "$prefix/share/wayland-sessions/niri.desktop"
  install_system 644 "$res/niri.service" "$prefix/lib/systemd/user/niri.service"
  install_system 644 "$res/niri-shutdown.target" "$prefix/lib/systemd/user/niri-shutdown.target"
  install_system 644 "$res/niri-portals.conf" /etc/xdg/xdg-desktop-portal/niri-portals.conf
)

build_rust_tool() (
  name=$1
  url=$2
  tag=$3
  rev=$4
  if command -v "$name" >/dev/null 2>&1; then
    say "$name already installed at $(command -v "$name")"
    exit 0
  fi
  say "building $name $tag from source"
  if [ "$dry" = 1 ]; then
    printf '  + build %s %s into %s\n' "$name" "$rev" "$prefix/bin/$name"
    exit 0
  fi
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  fetch_source "$work/src" "$url" "$tag" "$rev"
  cargo_build "$work"
  install_system 755 "$work/target/release/$name" "$prefix/bin/$name"
)

has_font() {
  fc-list : family 2>/dev/null | grep -qF "$1"
}

install_font() (
  family=$1
  url=$2
  sha=$3
  dir=$prefix/share/fonts/yurice
  has_font "$family" && exit 0
  say "installing the $family font"
  if [ "$dry" = 1 ]; then
    printf '  + fetch %s into %s\n' "$url" "$dir"
    exit 0
  fi
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  file=$work/$(basename "$url" | sed 's/%5B/[/g; s/%5D/]/g')
  fetch "$url" "$sha" "$file"
  sudo install -d "$dir"
  case $file in
    *.tar.xz) sudo tar -xJf "$file" -C "$dir" --wildcards '*.ttf' ;;
    *) sudo install -m644 "$file" "$dir/" ;;
  esac
  record "system $dir"
  sudo fc-cache -f "$dir"
)

install_gtk_theme() (
  dir=$prefix/share/themes
  if [ -d /usr/share/themes/adw-gtk3 ] || [ -d "$dir/adw-gtk3" ]; then
    exit 0
  fi
  say "installing the adw-gtk3 theme"
  if [ "$dry" = 1 ]; then
    printf '  + fetch %s into %s\n' "$adw_url" "$dir"
    exit 0
  fi
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  fetch "$adw_url" "$adw_sha256" "$work/adw-gtk3.tar.xz"
  sudo install -d "$dir"
  sudo tar -xJf "$work/adw-gtk3.tar.xz" -C "$dir"
  record "system $dir/adw-gtk3"
  record "system $dir/adw-gtk3-dark"
)

install_debian_desktop_extras() {
  build_niri
  build_rust_tool xwayland-satellite https://github.com/Supreeeme/xwayland-satellite "$satellite_tag" "$satellite_rev"
  build_rust_tool matugen https://github.com/InioX/matugen "$matugen_tag" "$matugen_rev"
  install_font "Agave Nerd Font" "$agave_url" "$agave_sha256"
  install_font "Material Symbols Sharp" "$symbols_url" "$symbols_sha256"
  install_gtk_theme
}

install_debian_terminal_extras() {
  install_font "Agave Nerd Font" "$agave_url" "$agave_sha256"
  for pair in bat:batcat fd:fdfind; do
    name=${pair%%:*}
    debian_name=${pair#*:}
    command -v "$name" >/dev/null 2>&1 && continue
    run sudo mkdir -p "$prefix/bin"
    run sudo ln -sfn "/usr/bin/$debian_name" "$prefix/bin/$name"
    record "system $prefix/bin/$name"
  done
}

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

  say "enabling the polkit agent"
  agent=""
  for candidate in \
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/libexec/polkit-mate-authentication-agent-1 \
    /usr/lib/mate-polkit/polkit-mate-authentication-agent-1; do
    if [ -x "$candidate" ]; then
      agent=$candidate
      break
    fi
  done
  if [ -n "$agent" ]; then
    sed "s|@agent@|$agent|" "$repo/dist/systemd/yurice-polkit-agent.service" |
      write_user "$config_home/systemd/user/yurice-polkit-agent.service"
    record "unit yurice-polkit-agent.service"
    run systemctl --user daemon-reload || true
    run systemctl --user enable yurice-polkit-agent.service ||
      warn "enable the polkit agent later with: systemctl --user enable yurice-polkit-agent.service"
  else
    warn "no polkit agent found; nautilus will not be able to mount drives that need a password"
  fi

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
  if [ "$distro" = debian ] && grep -E '^[[:space:]]*iface[[:space:]]' /etc/network/interfaces 2>/dev/null | grep -qvE 'iface[[:space:]]+lo[[:space:]]'; then
    warn "interfaces set up in /etc/network/interfaces are left to ifupdown and will not show in the wifi panel; remove them there to let NetworkManager manage them"
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
  case $distro in
    arch) greeter_user=greeter ;;
    debian) greeter_user=_greetd ;;
  esac
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
export PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:$PATH
exec niri -c /etc/yurice/greeter-niri.kdl >/dev/null 2>&1
EOF
  write_system /etc/yurice/hide-console.sh 755 <"$repo/dist/greeter/hide-console.sh"
  printf '[Unit]\nAfter=getty@tty1.service\nConflicts=getty@tty1.service\n\n[Service]\nExecStartPre=-/etc/yurice/hide-console.sh\n' |
    write_system /etc/systemd/system/greetd.service.d/yurice.conf 644
  record "system /etc/yurice"

  write_system /etc/tmpfiles.d/yurice.conf 644 <<EOF
d /var/lib/yurice 0755 root root -
d /var/lib/yurice/greeter 0755 $greeter_user $greeter_user -
d /var/lib/yurice/users 0755 root root -
d /var/lib/yurice/users/$(id -un) 0755 $(id -un) $(id -gn) -
EOF
  run sudo systemd-tmpfiles --create /etc/tmpfiles.d/yurice.conf

  if [ -f /etc/greetd/config.toml ] && ! grep -q yurice /etc/greetd/config.toml; then
    run sudo cp /etc/greetd/config.toml /etc/greetd/config.toml.yurice-backup
  fi
  write_system /etc/greetd/config.toml 644 <<EOF
[terminal]
vt = 1

[default_session]
command = "/etc/yurice/greeter-session.sh"
user = "$greeter_user"
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
      system) { [ -e "$path" ] || [ -L "$path" ]; } && run sudo rm -rf "$path" ;;
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
  if grep -q "^system $prefix/share/fonts/" "$manifest"; then
    run sudo fc-cache -f || true
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
  say "done. Keep $repo in place: your configs link into it."
  if has greeter; then
    say "reboot to get the greeter"
  elif has desktop; then
    say "log out and start niri (niri-session) to get the desktop"
  fi
}

main "$@"
