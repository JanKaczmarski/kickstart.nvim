return {
	"nvim-treesitter/nvim-treesitter",
	-- NOTE: master is fixed for 0.11 nvim verison compatibility
	-- when upgraing to nvim 0.12+ please use main branch
	branch = "master",
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
		highlight = {
			enable = true,
		},
	},
	config = function(_, opts)
		local configs = require("nvim-treesitter.configs")

		configs.setup(opts)

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
					-- Set up fallback indenting using Treesitter engine
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
