do
	local selene = require("efmls-configs.linters.selene")
	local stylua = require("efmls-configs.formatters.stylua")
	local alejandra = require("efmls-configs.formatters.alejandra")

	vim.lsp.config("efm", {
		filetypes = {
			"lua",
			"nix",
		},
		init_options = { documentFormatting = true },
		settings = {
			rootMarkers = { ".git/" },
			languages = {
				lua = { selene, stylua },
				nix = { alejandra },
			},
		},
	})
end
