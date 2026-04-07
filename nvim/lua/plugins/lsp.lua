-- =============================================================================
-- LSP Configuration (Neovim 0.10 & 0.11+ Support)
-- =============================================================================
local loader = require("lib.loader")
local lsp = vim.lsp

local capabilities = (function()
	local ok, blink = pcall(require, "blink.cmp")
	return ok and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()
end)()

-- Shared on_attach function for all servers
local on_attach = function(client, bufnr)
	local opts = function(desc)
		return { buffer = bufnr, silent = true, desc = desc }
	end
	vim.keymap.set("n", "gd", lsp.buf.definition, opts("Go to definition"))
	vim.keymap.set("n", "gD", lsp.buf.declaration, opts("Go to declaration"))
	vim.keymap.set("n", "gi", lsp.buf.implementation, opts("Go to implementation"))
	vim.keymap.set("n", "gr", lsp.buf.references, opts("References"))
	vim.keymap.set("n", "K", lsp.buf.hover, opts("Hover docs"))
	vim.keymap.set({ "n", "v" }, "<leader>ca", lsp.buf.code_action, opts("Code action"))
	vim.keymap.set("n", "<leader>lR", lsp.buf.rename, opts("Rename symbol"))

	-- Enable inlay hints if supported by the server
	if client.supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
	end
end

-- Fallback for Neovim 0.10 (where lsp.config doesn't exist)
if lsp.config then
	lsp.config("*", {
		capabilities = capabilities,
		on_attach = on_attach,
	})
end

lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, { border = "rounded" })

-- Helper to setup servers across different Neovim versions
local function setup_server(name, config)
	config = vim.tbl_deep_extend("force", {
		capabilities = capabilities,
		on_attach = on_attach,
	}, config or {})

	-- 0.11+ Native setup
	if lsp.enable then
		lsp.enable(name, config)
	else
		-- 0.10 legacy lspconfig setup
		local lspconfig = require("lspconfig")
		if lspconfig[name] then
			lspconfig[name].setup(config)
		end
	end
end

-- ── Language Server Definitions ───────────────────────────────────────────

-- Nix development (nixd)
setup_server("nixd", {
	settings = {
		nixd = {
			formatting = {
				command = { "nixfmt" },
			},
			options = {
				-- Adjust expressions to match your flake structure for better completion
				nixos = {
					expr = '(builtins.getFlake "/home/josh/NixConfig").nixosConfigurations.laptop.options',
				},
				["home-manager"] = {
					expr = '(builtins.getFlake "/home/josh/NixConfig").nixosConfigurations.laptop.options.home-manager.users.type.getSubOptions []',
				},
			},
		},
	},
})

-- Lua (lua_ls)
setup_server("lua_ls", {
	settings = {
		Lua = {
			hint = {
				enable = true,
				arrayIndex = "Disable",
			},
			telemetry = { enable = false },
			workspace = { checkThirdParty = false },
		},
	},
})

-- Other basic servers
local simple_servers = { "pyright", "vtsls", "kotlin_language_server", "jdtls", "marksman" }
for _, s in ipairs(simple_servers) do
	setup_server(s)
end

-- Roslyn (.NET) integration
loader.setup("roslyn", {
	config = {
		capabilities = capabilities,
		on_attach = on_attach,
		settings = {
			["csharp|inlay_hints"] = {
				csharp_enable_inlay_hints_for_implicit_object_creation = true,
				csharp_enable_inlay_hints_for_implicit_variable_types = true,
			},
		},
	},
})
