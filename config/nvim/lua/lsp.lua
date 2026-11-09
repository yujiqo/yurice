local diagnostic_signs = {
	Error = "\u{f057} ",
	Warn = "\u{f071} ",
	Hint = "\u{ea61}",
	Info = "\u{f05a}",
}

vim.diagnostic.config({
	virtual_text = { prefix = "", spacing = 4 },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
			[vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
			[vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
			[vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
		header = "",
		prefix = "",
		focusable = false,
		style = "minimal",
	},
})

do
	local orig = vim.lsp.util.open_floating_preview
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig(contents, syntax, opts, ...)
	end
end

require("mason").setup()

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			telemetry = { enable = false },
		},
	},
})

vim.lsp.config("nil_ls", {
	settings = {
		["nil"] = {
			nix = {
				flake = {
					autoArchive = true,
				},
			},
		},
	},
})

vim.lsp.config("qmlls", {
	cmd = { "qmlls" },
	filetypes = { "qml", "qmljs" },
	root_markers = { ".qmlls.ini", "shell.qml" },
	on_init = function(client)
		local st = client.server_capabilities.semanticTokensProvider
		if st and type(st.full) == "table" then
			st.full = true
		end
	end,
})

vim.lsp.enable({
	"efm",
	"lua_ls",
	"rust_analyzer",
	"nil_ls",
	"pyright",
	"svelte",
	"qmlls",
	"marksman",
	"sqls",
})
