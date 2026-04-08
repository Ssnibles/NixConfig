-- =============================================================================
-- LSP Configuration (Neovim 0.10 & 0.11+ Support)
-- =============================================================================
-- Language Server Protocol client configuration for multiple programming languages.
-- Supports both Neovim 0.10 (legacy lspconfig) and 0.11+ (native LSP config).
--
-- Features:
--   • Auto-completion integration via blink.cmp
--   • Inlay hints (type annotations, parameter names) - enabled by default
--   • Consistent keybindings across all language servers
--   • Rounded borders for hover windows
--   • LSP progress notifications via Fidget
--   • Version-agnostic server setup (0.10 and 0.11+)
--
-- Language Servers:
--   • Nix (nixd), Lua (lua-language-server)
--   • Python (pyright), TypeScript/JavaScript (vtsls)
--   • Kotlin (kotlin-language-server), Java (jdt-language-server)
--   • C# (roslyn-ls via roslyn.nvim), Markdown (marksman)
--
-- Note: LSP servers are installed via Nix (modules/home/neovim.nix)
-- =============================================================================

local loader = require("lib.loader")
local lsp = vim.lsp

-- ── Fidget (LSP Progress Notifications) ──────────────────────────────────────
-- Shows LSP server startup and indexing progress in a non-intrusive way
loader.setup("fidget", {
	progress = {
		display = {
			done_icon = "[OK]",
			progress_icon = { pattern = "dots", period = 1 },
			render_limit = 5,
			done_ttl = 2,
		},
	},
	notification = {
		window = {
			winblend = 0,
			border = "rounded",
		},
	},
})

-- ── Tiny Code Action (Lightweight UI) ────────────────────────────────────────
loader.setup("tiny-code-action", {
	backend = "vim",
	picker = "fzf-lua",
	notify = { enabled = true, on_empty = true },
})

-- ── Capabilities ─────────────────────────────────────────────────────────────
-- LSP capabilities enhanced with completion support from blink.cmp
-- Falls back to default Neovim capabilities if blink.cmp is not available
local capabilities = (function()
	local ok, blink = pcall(require, "blink.cmp")
	return ok and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()
end)()
capabilities.textDocument = capabilities.textDocument or {}
capabilities.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true,
}

local function with_snippet_support(value)
	local caps = vim.deepcopy(capabilities)
	caps.textDocument = caps.textDocument or {}
	caps.textDocument.completion = caps.textDocument.completion or {}
	caps.textDocument.completion.completionItem = caps.textDocument.completion.completionItem or {}
	caps.textDocument.completion.completionItem.snippetSupport = value
	return caps
end

local function resolve_flake_root(path)
	local fallback = vim.env.HOME .. "/NixConfig"
	if not path or path == "" then
		return fallback
	end
	if path:sub(-10) == "/flake.nix" then
		return path:sub(1, -11)
	end
	return path
end

local flake_root = resolve_flake_root(vim.env.NIX_CONFIG_FLAKE)
local flake_file = flake_root .. "/flake.nix"
local nix_host = vim.env.NIX_CONFIG_HOST or "laptop"

-- ── Global LSP Configuration ─────────────────────────────────────────────────
-- Neovim 0.11+ native LSP configuration (applies to all servers)
lsp.config("*", {
	capabilities = capabilities,
	on_attach = function(client, bufnr)
		-- Helper to create keymap options with description
		local opts = function(desc)
			return { buffer = bufnr, silent = true, desc = desc }
		end

		-- Enable inlay hints if the server supports them
		if client.supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		-- Prevent duplicate keymap registration
		if vim.b[bufnr]._lsp_keymaps_set then
			return
		end
		vim.b[bufnr]._lsp_keymaps_set = true

		-- Navigation keybindings
		vim.keymap.set("n", "gd", lsp.buf.definition, opts("Go to definition"))
		vim.keymap.set("n", "gD", lsp.buf.declaration, opts("Go to declaration"))
		vim.keymap.set("n", "gi", lsp.buf.implementation, opts("Go to implementation"))
		vim.keymap.set("n", "gr", lsp.buf.references, opts("Find references"))

		-- Documentation
		vim.keymap.set("n", "K", lsp.buf.hover, opts("Hover documentation"))

		-- Refactoring
		vim.keymap.set("n", "<leader>lR", lsp.buf.rename, opts("Rename symbol"))
	end,
})

-- Customize hover handler with rounded borders (better aesthetics)
lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, { border = "rounded" })
-- Signature help UI is provided by blink.cmp to avoid duplicate popups
lsp.handlers["textDocument/signatureHelp"] = function() end

-- ═════════════════════════════════════════════════════════════════════════════
-- LANGUAGE SERVER DEFINITIONS
-- ═════════════════════════════════════════════════════════════════════════════

-- Nix development (nixd)
lsp.config("nixd", {
	cmd = { "nixd" },
	capabilities = with_snippet_support(false),
	settings = {
		nixd = {
			nixpkgs = { expr = "import <nixpkgs> {}" },
			formatting = {
				command = { "nixfmt" },
			},
			flake = {
				flakePath = flake_file,
			},
			options = {
				-- Adjust expressions to match your flake structure for better completion
				nixos = {
					expr = string.format(
						'(builtins.getFlake "%s").nixosConfigurations.%s.options',
						flake_root,
						nix_host
					),
				},
				["home-manager"] = {
					expr = string.format(
						'(builtins.getFlake "%s").nixosConfigurations.%s.options.home-manager.users.type.getSubOptions []',
						flake_root,
						nix_host
					),
				},
			},
		},
	},
})

-- Lua (lua_ls)
lsp.config("lua_ls", {
	cmd = { "lua-language-server" },
	settings = {
		Lua = {
			hint = {
				enable = true,
				arrayIndex = "Disable",
			},
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			telemetry = { enable = false },
			workspace = { checkThirdParty = false },
		},
	},
})

-- Other basic servers
local simple_servers = { "pyright", "vtsls", "kotlin_language_server", "jdtls", "marksman" }
for _, server in ipairs(simple_servers) do
	lsp.config(server, {})
end

-- Roslyn (.NET) integration
loader.setup("roslyn", {
	config = {
		capabilities = capabilities,
		settings = {
			["csharp|inlay_hints"] = {
				csharp_enable_inlay_hints_for_implicit_object_creation = true,
				csharp_enable_inlay_hints_for_implicit_variable_types = true,
			},
		},
	},
})

for _, server in ipairs(vim.list_extend({ "nixd", "lua_ls" }, simple_servers)) do
	lsp.enable(server)
end
