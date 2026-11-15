local art = {
	[[      ___           ___           ___           ___                       ___      ]],
	[[     /\__\         /\  \         /\  \         /\__\          ___        /\__\     ]],
	[[    /::|  |       /::\  \       /::\  \       /:/  /         /\  \      /::|  |    ]],
	[[   /:|:|  |      /:/\:\  \     /:/\:\  \     /:/  /          \:\  \    /:|:|  |    ]],
	[[  /:/|:|  |__   /::\~\:\  \   /:/  \:\  \   /:/__/  ___      /::\__\  /:/|:|__|__  ]],
	[[ /:/ |:| /\__\ /:/\:\ \:\__\ /:/__/ \:\__\  |:|  | /\__\  __/:/\/__/ /:/ |::::\__\ ]],
	[[ \/__|:|/:/  / \:\~\:\ \/__/ \:\  \ /:/  /  |:|  |/:/  / /\/:/  /    \/__/~~/:/  / ]],
	[[     |:/:/  /   \:\ \:\__\    \:\  /:/  /   |:|__/:/  /  \::/__/           /:/  /  ]],
	[[     |::/  /     \:\ \/__/     \:\/:/  /     \::::/__/    \:\__\          /:/  /   ]],
	[[     /:/  /       \:\__\        \::/  /       ~~~~         \/__/         /:/  /    ]],
	[[     \/__/         \/__/         \/__/                                   \/__/     ]],
	[[                                                                                   ]],
}

local gradient = { "Function", "Keyword", "Type", "String" }

local ns = vim.api.nvim_create_namespace("splash")
local group = vim.api.nvim_create_augroup("Splash", { clear = true })
local reading_stdin = false

local win_opts = {
	number = false,
	relativenumber = false,
	cursorline = false,
	list = false,
	signcolumn = "no",
}

local function art_width()
	local width = 0
	for _, line in ipairs(art) do
		width = math.max(width, vim.fn.strdisplaywidth(line))
	end
	return width
end

local function render(buf, win)
	local top = math.max(0, math.floor((vim.api.nvim_win_get_height(win) - #art) / 2))
	local left = string.rep(" ", math.max(0, math.floor((vim.api.nvim_win_get_width(win) - art_width()) / 2)))

	local lines = {}
	for _ = 1, top do
		table.insert(lines, "")
	end
	for _, line in ipairs(art) do
		table.insert(lines, ((left .. line):gsub("%s+$", "")))
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].modified = false

	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for i = 1, #art do
		local hl = gradient[math.min(#gradient, math.floor((i - 1) * #gradient / #art) + 1)]
		local row = top + i - 1
		vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { end_col = #lines[row + 1], hl_group = hl })
	end

	vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

local function open()
	local buf = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].buflisted = false
	vim.bo[buf].filetype = "splash"

	local saved = {}
	for name, value in pairs(win_opts) do
		saved[name] = vim.wo[win][name]
		vim.api.nvim_set_option_value(name, value, { scope = "local", win = win })
	end

	render(buf, win)

	for _, key in ipairs({ "i", "a", "o" }) do
		vim.keymap.set("n", key, "<cmd>enew<bar>startinsert<cr>", { buffer = buf, nowait = true, silent = true })
	end

	vim.api.nvim_create_autocmd("VimResized", {
		group = group,
		buffer = buf,
		callback = function()
			if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
				render(buf, win)
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufWinLeave", {
		group = group,
		buffer = buf,
		once = true,
		callback = function()
			if not vim.api.nvim_win_is_valid(win) then
				return
			end
			vim.schedule(function()
				if not vim.api.nvim_win_is_valid(win) then
					return
				end
				for name, value in pairs(saved) do
					vim.api.nvim_set_option_value(name, value, { scope = "local", win = win })
				end
			end)
		end,
	})
end

vim.api.nvim_create_autocmd("StdinReadPre", {
	group = group,
	callback = function()
		reading_stdin = true
	end,
})

vim.api.nvim_create_autocmd("VimEnter", {
	group = group,
	callback = function()
		if reading_stdin or vim.fn.argc() > 0 then
			return
		end
		local buf = vim.api.nvim_get_current_buf()
		if vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified then
			return
		end
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		if #lines > 1 or lines[1] ~= "" then
			return
		end
		open()
	end,
})
