require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Install lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- Copy using OSC 52, but do NOT query terminal for paste
vim.g.clipboard = {
	name = "OSC 52",
	copy = {
		["+"] = require("vim.ui.clipboard.osc52").copy("+"),
		["*"] = require("vim.ui.clipboard.osc52").copy("*"),
	},
	paste = {
		["+"] = function()
			return {
				vim.fn.split(vim.fn.getreg(""), "\n"),
				vim.fn.getregtype(""),
			}
		end,
		["*"] = function()
			return {
				vim.fn.split(vim.fn.getreg(""), "\n"),
				vim.fn.getregtype(""),
			}
		end,
	},
}

vim.opt.clipboard = "unnamedplus"

-- Load all plugin specs from lua/plugins/
require("lazy").setup({ import = "plugins" }, {
	rocks = { enabled = false },
	ui = {
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})
