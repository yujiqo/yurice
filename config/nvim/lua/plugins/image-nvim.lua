require("image").setup({
	backend = "kitty",
	processor = "magick_cli",
	integrations = {
		markdown = {
			enabled = true,
			filetypes = { "markdown" },
			only_render_image_at_cursor = true,
			only_render_image_at_cursor_mode = "popup",
		},
	},
	hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
})
