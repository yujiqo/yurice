require("blink.cmp").setup({
	keymap = {
		preset = "none",
		["<C-Space>"] = { "show", "hide" },
		["<CR>"] = { "accept", "fallback" },
		["<Tab>"] = { "select_next", "fallback" },
		["<S-Tab>"] = { "select_prev", "fallback" },
		["<C-n>"] = { "snippet_forward", "fallback" },
		["<C-p>"] = { "snippet_backward", "fallback" },
	},
	completion = {
		menu = {
			auto_show = false,
			border = "rounded",
		},
	},
	sources = { default = { "lsp", "path", "buffer", "snippets" } },
	fuzzy = {
		implementation = "prefer_rust",
	},
})

vim.lsp.config["*"] = {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
}
