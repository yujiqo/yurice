# yurice ✨

A scroll-tiling rice built around **niri** and a custom **quickshell** shell.
Bring your own wallpaper; matugen turns it into a full Material You theme. // TODO: rewrite this fully

## Components

| Piece            | What it is                                    |
| ---------------- | --------------------------------------------- |
| niri             | Scroll-tiling Wayland compositor + keybinds   |
| quickshell       | Custom shell (status bar, launcher, widgets)  |
| nvim             | lazy.nvim setup, rose-pine, LSP, cmp          |
| kitty            | Transparent terminal, nerd font, cursor trail |
| fish + starship  | Prompt, aliases, git status                   |
| tmux             | tpm + tmux-yank, vim-pane navigation          |
| fastfetch        | Flexing with your system on screenshots       |

## Install

Non-Nix (coming soon): `./install.sh` symlinks `config/` into `~/.config` and
lays `custom/` over it.

Nix (coming soon): add as a flake input and import the home-manager module:

```nix
inputs.yurice = "github:<you>/yurice";
# home.nix
imports = [ inputs.yurice.homeModules.default ];
```

## Customizing

Everything personal intentionally lives in your own OS config, not here. To deviate from the defaults at runtime, drop files into `custom/` matching the same paths as `config/` — the installer applies them with precedence. Use it for experiments without forking the repo.

## Contributing

text about contributing

## Credits

credits to people

## License

about license
