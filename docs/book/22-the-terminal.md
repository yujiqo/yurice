# 22. The terminal

The terminal half of yurice is a set of plain config files: kitty, fish, starship, tmux, neovim, lazygit, less and fastfetch. None of them depends on the shell. You can install them alone with `./install.sh terminal`, or link them by hand on a system the installer doesn't support, like macOS. What ties them to the desktop is two shared habits, which this chapter follows through each program:

- each one reads a color file that matugen generates from your wallpaper, and reloads it when it changes;
- each one ends by loading an optional file from `~/.config/yurice/custom/`, so you can override anything without editing the repo.

## How they're installed

The installer links the repo's files into `~/.config` (chapter 23). Most programs get their whole folder linked: `fish`, `tmux`, `nvim`, `lazygit`, `fastfetch`. Two are linked file by file instead. Starship only needs `starship.toml`. kitty gets `kitty.conf` and `current-theme.conf` linked, but its folder stays a real directory, because one file in it has to be different on every machine.

That file is `kitty.local.conf`. It holds a single line, the path to fish:

```conf
shell /usr/bin/fish
```

fish lives in `/usr/bin` on Arch and Debian and in the Nix store on NixOS, so the path can't be written into the shared `kitty.conf`. The installer writes the right one for your system, and the Nix home module does the same. It's also in `.gitignore`, along with fish's `fish_variables`, the other file that's always machine-specific.

## kitty

[`config/kitty/kitty.conf`](../../config/kitty/kitty.conf) sets the font (Agave Nerd Font at 15, ligatures off), a block cursor with a short trail, 30 pixels of padding, 80% background opacity with blur, and no title bar. The end of the file is the part that matters for yurice:

```conf
include current-theme.conf

include ${HOME}/.cache/yurice/kitty-colors.conf

cursor none

include kitty.local.conf

include ${HOME}/.config/yurice/custom/kitty/kitty.conf
```

[`config/kitty/kitty.conf:41-51`](../../config/kitty/kitty.conf#L41-L51)

The includes go from general to specific, and later lines win. `current-theme.conf` is Rosé Pine, a fixed theme used until matugen has run once. `kitty-colors.conf` is matugen's output and overrides it. Then the local shell, then your custom file. kitty ignores includes that don't exist, so all of them are optional.

matugen's post hook is `pkill -USR1 kitty`. kitty reloads its config on `SIGUSR1`, so every open window switches colors with the wallpaper, no restart needed.

The 16 ANSI colors come from matugen's custom colors (chapter 3), blended toward the wallpaper: red is the `bad` color, green is `good`, blue is `wifi`, and so on, with the bright variants from their matching "on container" colors. Red stays recognizably red for errors and green for success, while still matching the theme.

## fish

[`config/fish/config.fish`](../../config/fish/config.fish) is short. In interactive shells it starts starship, sets `EDITOR` to nvim, and replaces a few commands with nicer ones:

```fish
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -lah --icons --group-directories-first"
  alias l="eza -lh --icons --group-directories-first"
  alias tree="eza --tree --icons --group-directories-first"
  alias less="less -S"
  alias cat="bat --theme base16-256 -S"
  alias top="btop"
  alias lgit="lazygit"
```

[`config/fish/config.fish:6-13`](../../config/fish/config.fish#L6-L13)

`bat --theme base16-256` uses the terminal's own 16 colors instead of a built-in theme, so `cat` output follows the wallpaper through kitty. `files` opens Nautilus in the current folder detached from the terminal. The greeting is turned off.

The last two lines load your custom file:

```fish
set -l custom ~/.config/yurice/custom/fish/config.fish
test -f $custom; and source $custom
```

[`config/fish/config.fish:60-61`](../../config/fish/config.fish#L60-L61)

That's the place for your own aliases, abbreviations and `PATH` entries.

## starship

[`config/starship/starship.toml`](../../config/starship/starship.toml) keeps the prompt to one line: the Python virtualenv if there is one, the directory (shortened to 4 parts and to the repo root), the git branch and status, and a `❯` that turns red after a failed command. Username, hostname and package versions are off. Its colors are plain terminal colors (`green`, `red`, `purple`), so they also come from kitty's palette.

## tmux

[`config/tmux/tmux.conf`](../../config/tmux/tmux.conf) moves the prefix to `Ctrl+A`, splits with `prefix h` and `prefix v` in the current folder, turns the mouse on, and loads [tpm](https://github.com/tmux-plugins/tpm) with tmux-yank for copying.

The pane navigation is shared with neovim:

```conf
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
bind-key -n "C-h" if-shell "$is_vim" "send-keys C-h"  "select-pane -L"
bind-key -n "C-j" if-shell "$is_vim" "send-keys C-j"  "select-pane -D"
bind-key -n "C-k" if-shell "$is_vim" "send-keys C-k"  "select-pane -U"
bind-key -n "C-l" if-shell "$is_vim" "send-keys C-l"  "select-pane -R"
```

[`config/tmux/tmux.conf:20-25`](../../config/tmux/tmux.conf#L20-L25)

`Ctrl+hjkl` moves between tmux panes, unless the current pane is running vim or fzf, in which case the keys are passed through. On the neovim side, vim-tmux-navigator does the opposite: it moves between vim splits and hands off to tmux at the edge. Together, `Ctrl+hjkl` moves across vim splits and tmux panes as if they were one grid. It's the same `hjkl` habit as niri's `Mod+hjkl` and the panels' `hjkl` (chapter 12), one level down.

Colors come from `~/.cache/yurice/tmux-colors.conf`, loaded with `source-file -q` so a missing file is fine. matugen's post hook runs `tmux source-file` on it, so running tmux sessions recolor too. The custom file is loaded the same way, just before plugins start.

## neovim

[`config/nvim/init.lua`](../../config/nvim/init.lua) just loads modules in order: transparency, options, keymaps, autocmds, plugins, a splash screen, LSP, linting and formatting, completion, and finally your custom file:

```lua
local custom = vim.fn.expand("~/.config/yurice/custom/nvim/init.lua")
if vim.fn.filereadable(custom) == 1 then
	dofile(custom)
end
```

[`config/nvim/init.lua:49-52`](../../config/nvim/init.lua#L49-L52)

### Plugins with vim.pack

There's no plugin manager plugin. Neovim 0.12 has a built-in one, `vim.pack`:

```lua
vim.pack.add({
	{ src = github .. "rose-pine/neovim", name = "rose-pine" },
	{ src = github .. "echasnovski/mini.nvim" },
	{ src = github .. "ibhagwan/fzf-lua" },
	{ src = github .. "christoomey/vim-tmux-navigator" },
	...
	{ src = github .. "neovim/nvim-lspconfig" },
	{ src = github .. "mason-org/mason.nvim" },
	{ src = github .. "creativenull/efmls-configs-nvim" },
	{ src = github .. "saghen/blink.lib" },
	{ src = github .. "saghen/blink.cmp" },
})
```

[`config/nvim/lua/plugins/init.lua:3-17`](../../config/nvim/lua/plugins/init.lua#L3-L17)

`vim.pack` clones missing plugins on first start, and records the exact commit of each in [`nvim-pack-lock.json`](../../config/nvim/nvim-pack-lock.json), which is committed. Everyone who installs yurice gets the same plugin versions. On Debian, where the packaged neovim is too old, the installer downloads a pinned upstream release (v0.12.6) and checks its checksum (chapter 23).

The plugins are few. mini.nvim provides comments, surround, indent guides, trailing space, icons, a file explorer and git signs in one package. fzf-lua does finding (`Space ff` files, `Space fg` grep, `Space fb` buffers). image.nvim shows images in kitty, and markdown-plus helps with markdown editing.

### Colors

[`lua/plugins/colorscheme.lua`](../../config/nvim/lua/plugins/colorscheme.lua) uses matugen's palette when it exists and Rosé Pine when it doesn't:

```lua
local palette_file = vim.fn.expand("~/.cache/yurice/nvim-colors.lua")

local function apply()
	local ok, palette = pcall(dofile, palette_file)
	if ok and type(palette) == "table" then
		vim.cmd("highlight clear")
		require("mini.base16").setup({ palette = palette, use_cterm = true })
		vim.g.colors_name = "yurice"
	else
		vim.cmd("colorscheme rose-pine")
	end
	require("transparency").apply()
end

apply()

vim.api.nvim_create_autocmd("Signal", {
	pattern = "SIGUSR1",
	desc = "reload wallpaper colors",
	callback = function()
		apply()
		vim.cmd("redraw!")
	end,
})
```

[`config/nvim/lua/plugins/colorscheme.lua:10-33`](../../config/nvim/lua/plugins/colorscheme.lua#L10-L33)

matugen's [`nvim.lua` template](../../config/matugen/templates/nvim.lua) writes a Lua file that returns a base16 palette: 16 colors, `base00` to `base0F`, that the `mini.base16` plugin turns into a full colorscheme. The first eight are backgrounds and text from the Material roles. The last eight are accents, mostly from matugen's custom colors, used for errors, warnings, strings and so on.

Neovim has a `Signal` autocmd for `SIGUSR1`. matugen's post hook sends that signal to every running nvim (`pkill -USR1 -x nvim`), and each one reloads the palette and redraws. Your open editors change colors with the wallpaper, the same as kitty.

`transparency.lua` then clears the background of every highlight group that used the normal background color, so kitty's translucent background and blur show through the editor.

### Language servers

[`lua/lsp.lua`](../../config/nvim/lua/lsp.lua) enables servers with neovim's built-in `vim.lsp.enable`, using configs from nvim-lspconfig: Lua, Rust, Nix, Python, Svelte, QML (`qmlls`, which reads the `.qmlls.ini` quickshell generates), Markdown and SQL. mason.nvim can install them on systems that don't package them.

Formatting and linting go through one more server, efm-langserver, set up in [`lua/efmls.lua`](../../config/nvim/lua/efmls.lua). It runs stylua and selene for Lua, alejandra for Nix, rustfmt, prettier for Markdown, ruff for Python, sql-formatter, and `qmlformat -w 2` for QML. That last one is how yurice's own QML stays formatted with two-space indents. Completion is blink.cmp.

## lazygit and less

[`config/lazygit/config.yml`](../../config/lazygit/config.yml) has one setting: don't ask "press enter to return" after running a command.

[`config/less/key`](../../config/less/key) is linked to `~/.lesskey` and binds `h` and `l` to scroll sideways. fish's `less` alias adds `-S`, which turns off line wrapping, so long lines can be scrolled with `h` and `l` like in vim.

## fastfetch

fastfetch is the system info printout. Its config is a matugen template, [`fastfetch.jsonc`](../../config/matugen/templates/fastfetch.jsonc), so its key and title colors are the wallpaper's primary color, written as 24-bit escape codes (`38;2;r;g;b`). It's grouped into system, desktop and hardware sections. The terminal and font rows are small scripts: [`terminal-name.sh`](../../config/fastfetch/terminal-name.sh) reports kitty even inside tmux, where fastfetch would otherwise just see "tmux", and [`kitty-font.sh`](../../config/fastfetch/kitty-font.sh) reads the font from kitty's config files, your custom one included.

The `fastfetch` command is replaced by a fish function. When run plainly in a terminal, it shows your distro's logo from [`config/fastfetch/images/`](../../config/fastfetch/images) as a real image through kitty's graphics protocol, sized to 15 or 16 rows depending on how tall the text is so it's vertically centered, and wraps long lines with [`wrap.awk`](../../config/fastfetch/wrap.awk) so the text never runs into the logo. With arguments, or when its output isn't a terminal, it falls back to normal fastfetch with the generated config.

That's the end of Part V. Everything yurice puts on your screen is now covered. Part VI is about getting it onto a machine and keeping it working.
