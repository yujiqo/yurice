do
	local selene = require("efmls-configs.linters.selene")
	local stylua = require("efmls-configs.formatters.stylua")

	vim.lsp.config("efm", {
		filetypes = {
			"lua",
		},
		init_options = { documentFormatting = true },
		settings = {
			languages = {
				lua = { selene, stylua },
			},
		},
	})
end
