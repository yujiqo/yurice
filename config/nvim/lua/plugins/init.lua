local github = "https://www.github.com/"

vim.pack.add({
	{ src = github .. "rose-pine/neovim", name = "rose-pine" },
	{ src = github .. "echasnovski/mini.nvim" },
	{ src = github .. "ibhagwan/fzf-lua" },
	{ src = github .. "christoomey/vim-tmux-navigator" },

	{ src = github .. "neovim/nvim-lspconfig" },
	{ src = github .. "mason-org/mason.nvim" },
	{ src = github .. "creativenull/efmls-configs-nvim" },
	{ src = github .. "saghen/blink.lib" },
	{ src = github .. "saghen/blink.cmp" },
})

require("plugins/rose-pine")
require("plugins/mini-nvim")
require("plugins/fzf-lua")
