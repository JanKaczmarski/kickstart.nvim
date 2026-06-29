return {
	"mfussenegger/nvim-lint",
	event = { "BufWritePost" },
	cmd = { "LintInfo" },
	keys = {
		{
			"<leader>l",
			function()
				require("lint").try_lint()
			end,
			mode = "",
			desc = "[L]int buffer",
		},
	},
	config = function()
		require("lint").linters_by_ft = {
			python = { "ruff" },
		}

		require("lint").linters.ruff.args = { "--max-line-length", "120" }

		-- Automatically trigger linting on save and buffer read
		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
			callback = function()
				require("lint").try_lint()
			end,
		})
	end,
}
