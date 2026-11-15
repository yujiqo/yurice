require("markview").setup({
	preview = {
		enable = false,
		icon_provider = "mini",
	},
})

vim.api.nvim_set_keymap("n", "<leader>tp", "<CMD>Markview<CR>", { desc = "Toggles `markview` previews globally." })
