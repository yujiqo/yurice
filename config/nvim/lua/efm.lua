do
	local selene = require("efmls-configs.linters.selene")
	local stylua = require("efmls-configs.formatters.stylua")
	local alejandra = require("efmls-configs.formatters.alejandra")
	local prettier = require("efmls-configs.formatters.prettier")
	local sql_formatter = require("efmls-configs.formatters.sql-formatter")
	local ruff_linter = require("efmls-configs.linters.ruff")
	local ruff_formatter = require("efmls-configs.formatters.ruff")

	vim.lsp.config("efm", {
		filetypes = {
			"lua",
			"nix",
			"markdown",
			"sql",
			"python",
		},
		init_options = { documentFormatting = true },
		settings = {
			rootMarkers = { ".git/" },
			languages = {
				lua = { selene, stylua },
				nix = { alejandra },
				markdown = { prettier },
				sql = { sql_formatter },
				python = { ruff_linter, ruff_formatter },
			},
		},
	})
end
