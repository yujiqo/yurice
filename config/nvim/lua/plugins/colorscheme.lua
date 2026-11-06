require("rose-pine").setup({
	variant = "moon",
	styles = {
		bold = false,
		italic = false,
		transparency = true,
	},
})

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
