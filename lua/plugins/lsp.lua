return {
	{
		-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
		-- used for completion, annotations and signatures of Neovim apis
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},
	{ "Bilal2453/luvit-meta", lazy = true },
	{
		"ray-x/lsp_signature.nvim",
		event = "LspAttach",
		opts = {
			hint_enable = false, -- disable virtual text hints, use floating window only
			handler_opts = {
				border = "rounded",
			},
		},
	},
	{
		-- Main LSP Configuration
		"neovim/nvim-lspconfig",
		version = "v1.*",
		dependencies = {
			-- Pin Mason to the last 1.x version
			{ "williamboman/mason.nvim", version = "v1.11.0", config = true },

			-- Pin Mason-lspconfig to the last 1.x version
			{ "williamboman/mason-lspconfig.nvim", version = "v1.32.0" },

			-- Mason-tool-installer: Pinned to a stable tag before the Mason 2.0 shift
			{ "WhoIsSethDaniel/mason-tool-installer.nvim", version = "v1.3.0" },

			-- Status updates for LSP (Generally stable, but pinning ensures no 0.11+ API calls)
			{ "j-hui/fidget.nvim", version = "v1.6.0", opts = {} },

			-- Extra capabilities for nvim-cmp (Unchanged)
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			--  This function gets run when an LSP attaches to a particular buffer.
			--    That is to say, every time a new file is opened that is associated with
			--    an lsp (for example, opening `main.go` is associated with `gopls`) this
			--    function will be executed to configure the current buffer
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- Jump to the definition of the word under your cursor.
					--  To jump back, press <C-t>.
					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

					-- Find references for the word under your cursor.
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

					-- Jump to the implementation of the word under your cursor.
					map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

					-- Jump to the type of the word under your cursor.
					map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

					-- Fuzzy find all the symbols in your current document.
					map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

					-- Fuzzy find all the symbols in your current workspace.
					map(
						"<leader>ws",
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[W]orkspace [S]ymbols"
					)

					-- Rename the variable under your cursor.
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

					-- Execute a code action, usually your cursor needs to be on top of an error
					-- or a suggestion from your LSP for this to activate.
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

					-- Goto Declaration. For example, in C this would take you to the header.
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					-- Highlight references of the word under your cursor when it rests there.
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					-- Toggle inlay hints if the language server supports them
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			-- Broadcast nvim-cmp capabilities to LSP servers
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			-- Enable the following language servers
			local servers = {
				gopls = {
					settings = {
						gopls = {
							buildFlags = { "-tags=integration,unit,e2e" },
							gofumpt = true,
							staticcheck = true,
							analyses = {
								unusedparams = true,
								shadow = true,
								nilness = true,
								unusedwrite = true,
							},
							hints = {
								assignVariableTypes = true,
								compositeLiteralFields = true,
								constantValues = true,
								functionTypeParameters = true,
								parameterNames = true,
								rangeVariableTypes = true,
							},
						},
					},
				},
				golangci_lint_ls = {
					filetypes = { "go" },
					init_options = {
						command = { "golangci-lint", "run", "--output.json.path=stdout", "--show-stats=false" },
					},
				},
				clangd = {
					cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed" },
					capabilities = vim.tbl_deep_extend("force", capabilities, {
						offsetEncoding = { "utf-16" }, -- compliance with protols
					}),
					filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }, -- don't apply to unecessary filetypes
				},
				pyright = {},
				gitlab_ci_ls = {
					filetypes = { "yaml.gitlab" },
				},
				yamlls = {
					format = {
						enable = true,
					},
					schemas = {
						{
							["yaml.gitlab"] = "https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/editor/schema/ci.json",
						},
					},
					validate = true,
					completion = true,
				},
				elixirls = {
					cmd = { "/Users/jkaczmarski/.elixir-ls/language_server.sh" },
					filetypes = { "elixir", "eelixir", "heex", "surface" },
				},
				rust_analyzer = {},
				docker_compose_language_service = {},
				dockerls = {},
				lua_ls = {
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
						},
					},
				},
			}

			require("mason").setup()

			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"stylua", -- Used to format Lua code
				"goimports", -- Go import organizer
				"gofumpt", -- Strict Go formatter
				"delve", -- Go debugger
				"clang-format", -- C/C++ formatter
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
			-- mapping doesn't exit in mason-lspconfig - has to be done manually
			require("lspconfig").protols.setup({
				capabilities = capabilities,
			})
		end,
	},
}
