return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	opts = {
		ensure_installed = {
			"bash",
			"c",
			"diff",
			"go",
			"gomod",
			"gosum",
			"html",
			"json",
			"lua",
			"luadoc",
			"markdown",
			"markdown_inline",
			"query",
			"ssh_config",
			"vim",
			"vimdoc",
		},
	},
	config = function(_, opts)
		local treesitter = require("nvim-treesitter")
		local install_dir = vim.fn.stdpath("data") .. "/site"

		treesitter.setup({ install_dir = install_dir })
		treesitter.install(opts.ensure_installed)

		local enabled = {}
		for _, lang in ipairs(opts.ensure_installed) do
			enabled[lang] = true
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("custom-treesitter", { clear = true }),
			callback = function(args)
				local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
				if not enabled[lang] then
					return
				end

				if pcall(vim.treesitter.start, args.buf, lang) then
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
