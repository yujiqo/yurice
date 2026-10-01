require("mini.comment").setup()
require("mini.surround").setup()
require("mini.indentscope").setup()
require("mini.trailspace").setup()
require("mini.icons").setup()
require("mini.files").setup()
require("mini.git").setup()
require("mini.diff").setup({ view = { style = "sign" } })

vim.keymap.set("n", "<leader>e", ":lua MiniFiles.open()<CR>", { desc = "open mini file manager" })

vim.keymap.set("n", "<leader>te", ":lua MiniTrailspace.trim()<CR>", { desc = "trim all trailspaces" })
vim.keymap.set("n", "<leader>tl", ":lua MiniTrailspace.trim_last_lines()<CR>", { desc = "trim all last lines" })
