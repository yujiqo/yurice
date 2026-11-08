------------------
-- transparency --
------------------
require("transparency")

-------------
-- options --
-------------
require("options")

-------------
-- keymaps --
-------------
require("keymaps")

--------------
-- autocmds --
--------------
require("autocmds")

-------------
-- plugins --
-------------
require("plugins")

---------
-- lsp --
---------
require("lsp")

--------------------------
-- linting & formatting --
--------------------------
require("efm")

----------------
-- completion --
----------------
require("cmp")

---------------------
-- custom settings --
---------------------
local custom = vim.fn.expand("~/.config/yurice/custom/nvim/init.lua")
if vim.fn.filereadable(custom) == 1 then
	dofile(custom)
end
