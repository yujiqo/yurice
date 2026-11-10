local always = {
	"Normal",
	"NormalNC",
	"EndOfBuffer",
	"NormalFloat",
	"FloatBorder",
	"SignColumn",
	"StatusLine",
	"StatusLineNC",
	"TabLine",
	"TabLineFill",
	"TabLineSel",
	"ColorColumn",
	"Pmenu",
}

local gutter_patterns = {
	"LineNr",
	"SignColumn",
	"FoldColumn",
	"CursorLineSign",
	"CursorLineFold",
	"Sign",
	"^DiagnosticFloating",
	"^StatusLine",
	"^TabLine",
	"^WinBar",
	"^MiniStatusline",
	"^MiniTabline",
}

local function is_gutter(name)
	for _, pattern in ipairs(gutter_patterns) do
		if name:find(pattern) then
			return true
		end
	end
	return false
end

local function clear_bg(name, hl)
	hl.bg = nil
	hl.ctermbg = nil
	vim.api.nvim_set_hl(0, name, hl)
end

local function set_transparent()
	local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
	local gutter_bg = vim.api.nvim_get_hl(0, { name = "LineNr", link = false }).bg

	for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
		if not hl.link and hl.bg then
			if hl.bg == normal_bg or (hl.bg == gutter_bg and is_gutter(name)) then
				clear_bg(name, hl)
			end
		end
	end

	for _, name in ipairs(always) do
		clear_bg(name, vim.api.nvim_get_hl(0, { name = name, link = false }))
	end

	vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none", fg = "#767676" })
	vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { link = "FloatBorder" })
	vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { link = "FloatBorder" })
	vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelpBorder", { link = "FloatBorder" })
end

set_transparent()

return { apply = set_transparent }
