vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "j", function()
	return vim.v.count == 0 and "gj" or "j"
end, { expr = true, silent = true, desc = "down (wrap-aware)" })
vim.keymap.set("n", "k", function()
	return vim.v.count == 0 and "gk" or "k"
end, { expr = true, silent = true, desc = "up (wrap-aware)" })

vim.keymap.set("n", "<leader>nh", ":nohlsearch<CR>", { desc = "clear search highlights" })

vim.keymap.set("n", "n", "nzzzv", { desc = "next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "half page up (centered)" })

vim.keymap.set("x", "<leader>p", '"_dP', { desc = "paste without yanking" })
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "delete without yanking" })

vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", { desc = "move to left window/pane" })
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", { desc = "move to bottom window/pane" })
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", { desc = "move to top window/pane" })
vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", { desc = "move to right window/pane" })

vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "split window vertically" })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "split window horizontally" })
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "increase window height" })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "decrease window height" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "decrease window width" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "increase window width" })

vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "move line down" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "move line up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "move selection up" })

vim.keymap.set("v", "<", "<gv", { desc = "indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "indent right and reselect" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "join lines and keep cursor position" })

vim.keymap.set("n", "<leader>td", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "toggle diagnostics" })
