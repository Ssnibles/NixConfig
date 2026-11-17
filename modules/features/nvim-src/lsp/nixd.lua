-- nixd: the flake root and host have to be detected at runtime, so the whole
-- config is built here rather than being a static table.

local NIX_FALLBACK_DIR = (vim.env.HOME or "~") .. "/NixConfig"
local NIX_DEFAULT_HOST = "desktop"

local function detect_flake_root()
	local from_env = vim.env.NIX_CONFIG_FLAKE
	if from_env and from_env ~= "" then
		local root = from_env:gsub("/flake.nix$", "")
		if vim.uv.fs_stat(root .. "/flake.nix") then
			return root
		end
	end

	local flake = vim.fs.find("flake.nix", { path = vim.uv.cwd() or vim.fn.getcwd(), upward = true })[1]
	if flake then
		return vim.fs.dirname(flake)
	end

	if vim.uv.fs_stat(NIX_FALLBACK_DIR .. "/flake.nix") then
		return NIX_FALLBACK_DIR
	end
end

local function host_exists(root, host)
	if not root or host == "" then
		return false
	end
	return vim.uv.fs_stat(("%s/modules/hosts/%s"):format(root, host)) ~= nil
end

local function detect_nix_host(root)
	local from_env = vim.env.NIX_CONFIG_HOST
	if from_env and from_env ~= "" and (not root or host_exists(root, from_env)) then
		return from_env
	end

	local hostname = (vim.uv.os_gethostname() or ""):match("^[^.]+") or ""
	if hostname ~= "" and host_exists(root, hostname) then
		return hostname
	end
	if host_exists(root, "desktop") then
		return "desktop"
	end
	if host_exists(root, "laptop") then
		return "laptop"
	end
	return hostname ~= "" and hostname or NIX_DEFAULT_HOST
end

local function nix_string(value)
	return ('"%s"'):format(value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("%${", "\\${"))
end

local root = detect_flake_root()
local ref = root and nix_string(root)
local attr = nix_string(detect_nix_host(root))

local nixpkgs_expr = "import <nixpkgs> {}"
local options = {}

if ref then
	nixpkgs_expr = ([[
let
  flake = builtins.getFlake %s;
  system = builtins.currentSystem;
  pkgs = import flake.inputs.nixpkgs { inherit system; config = { allowUnfree = true; }; };
  unstable = import flake.inputs."nixpkgs-unstable" { inherit system; config = { allowUnfree = true; }; };
in
  pkgs // { unstable = unstable; }
]]):format(ref)

	options = {
		nixos = { expr = ("(builtins.getFlake %s).nixosConfigurations.%s.options"):format(ref, attr) },
		hjem = {
			expr = ("(builtins.getFlake %s).nixosConfigurations.%s.options.hjem.users.type.getSubOptions []"):format(
				ref,
				attr
			),
		},
	}
end

return {
	cmd = { "nixd" },
	filetypes = { "nix" },
	root_markers = { "flake.nix", ".git" },
	settings = {
		nixd = {
			nixpkgs = { expr = nixpkgs_expr },
			formatting = { command = { "nixfmt" } },
			options = options,
		},
	},
}
