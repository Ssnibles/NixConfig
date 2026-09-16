# =============================================================================
# Helium Browser Feature
# =============================================================================
# Helium Browser installation, Chrome Enterprise policies, command-line flags,
# and default xdg-open MIME associations via oxcl/nix-flake-helium-browser.
# =============================================================================
{ inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.helium;
      cfgAlias = config.features.helium-browser;
      enabled = cfg.enable || cfgAlias.enable;
      isDefaultBrowser = cfg.defaultBrowser || cfgAlias.defaultBrowser;
      effectiveFlags = cfg.extraFlags ++ cfgAlias.extraFlags;
      effectivePolicies = cfg.policies // cfgAlias.policies;
    in
    {
      imports = [
        inputs.helium.nixosModules.default
      ];

      options.features.helium = {
        enable = lib.mkEnableOption "Helium Browser";

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.helium;
          defaultText = lib.literalExpression "inputs.helium.packages.\${pkgs.stdenv.hostPlatform.system}.helium";
          description = "The Helium package to use.";
        };

        defaultBrowser = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Set Helium as the default browser in xdg.mime and DEFAULT_BROWSER.";
        };

        extraFlags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "--ozone-platform-hint=auto" "--enable-features=TouchpadOverscrollHistoryNavigation" ];
          description = "Additional command-line flags to pass to the Helium wrapper.";
        };

        policies = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          example = lib.literalExpression ''
            {
              BrowserSignin = 0;
              PasswordManagerEnabled = false;
            }
          '';
          description = ''
            Chrome Enterprise policies written to /etc/chromium/policies/managed/helium-nixos.json
            and /etc/helium/policies/managed/helium-nixos.json.
          '';
        };
      };

      # Alias options for convenience (features.helium-browser.*)
      options.features.helium-browser = {
        enable = lib.mkEnableOption "Helium Browser (alias for features.helium)";

        defaultBrowser = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Alias for features.helium.defaultBrowser.";
        };

        extraFlags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Alias for features.helium.extraFlags.";
        };

        policies = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Alias for features.helium.policies.";
        };
      };

      config = lib.mkIf enabled {
        programs.helium = {
          enable = true;
          package = cfg.package;
          flags = effectiveFlags;
          policies = effectivePolicies;
        };

        environment.systemPackages = [
          (pkgs.writeShellScriptBin "helium-browser" ''exec helium "$@"'')
        ];

        features.default-apps.browser = lib.mkIf isDefaultBrowser (lib.mkDefault "helium");
      };
    };
}
