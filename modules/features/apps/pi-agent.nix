# =============================================================================
# Pi Coding Agent Feature
# =============================================================================
# Terminal coding agent harness (github:lukasl-dev/pi.nix) providing AI-assisted
# coding, tool calling, skills, prompt extensions, and optional Bubblewrap
# sandboxing (jail.nix).
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
      cfg = config.features.pi-agent;

      effectivePackage =
        if cfg.useBun then
          inputs.pi-agent.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent-bun
        else
          cfg.package;

      extDir = "${effectivePackage}/lib/node_modules/@earendil-works/pi-coding-agent/examples/extensions";

      enabledBuiltinExtensions =
        lib.optional cfg.planMode "${extDir}/plan-mode/index.ts"
        ++ lib.optional (cfg.interactiveChoice || cfg.questionnaire) "${extDir}/questionnaire.ts"
        ++ lib.optional cfg.question "${extDir}/question.ts"
        ++ lib.optional cfg.gitCheckpoint "${extDir}/git-checkpoint.ts"
        ++ lib.optional cfg.protectedPaths "${extDir}/protected-paths.ts"
        ++ lib.optional cfg.permissionGate "${extDir}/permission-gate.ts"
        ++ lib.optional cfg.subagent "${extDir}/subagent/index.ts";

      headerExtension = lib.optional cfg.header ./pi-agent/custom-header.ts;

      allExtensions = enabledBuiltinExtensions ++ headerExtension ++ cfg.extensions;

      defaultSettings = {
        defaultProvider = cfg.defaultProvider;
        defaultModel = cfg.defaultModel;
      };
    in
    {
      imports = [
        inputs.pi-agent.nixosModules.default
      ];

      options.features.pi-agent = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable the Pi terminal coding agent.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.pi-agent.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent;
          defaultText = lib.literalExpression "inputs.pi-agent.packages.\${pkgs.stdenv.hostPlatform.system}.coding-agent";
          description = "The pi package to install.";
        };

        useBun = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to use the Bun-built pi package variant instead of npm.";
        };

        jail = {
          enable = lib.mkEnableOption "Bubblewrap isolation for pi using jail.nix";
        };

        # ── Built-in Extension Toggles ─────────────────────────────────────────
        interactiveChoice = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable interactive choice/question prompts (questionnaire tool for single and multi-question select prompts with custom input).";
        };

        questionnaire = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Alias for interactiveChoice.";
        };

        question = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable lightweight single-question choice prompt extension (question.ts).";
        };

        planMode = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable plan-mode extension (adds /plan command and --plan flag for read-only exploration).";
        };

        gitCheckpoint = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable git-checkpoint extension (creates automatic git stash checkpoints per turn for rollback).";
        };

        protectedPaths = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable protected-paths extension (blocks writes to sensitive paths like .env, .git/, node_modules/).";
        };

        permissionGate = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable permission-gate extension (prompts for confirmation before destructive shell commands).";
        };

        subagent = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable subagent extension (delegate tasks to specialized subagents with isolated context).";
        };

        extensions = lib.mkOption {
          type = lib.types.listOf (lib.types.either lib.types.path lib.types.str);
          default = [ ];
          description = "List of custom extension paths or TypeScript files passed to pi via --extension.";
        };

        header = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Replace the default startup header with a custom pi mascot header (ASCII art + session info).";
        };

        defaultProvider = lib.mkOption {
          type = lib.types.str;
          default = "deepseek";
          description = "Default model provider written to pi settings.json.";
        };

        defaultModel = lib.mkOption {
          type = lib.types.str;
          default = "deepseek-flash";
          description = "Default model written to pi settings.json.";
        };

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          example = lib.literalExpression ''
            {
              defaultProvider = "anthropic";
              defaultModel = "claude-3-7-sonnet";
            }
          '';
          description = "Settings merged into ~/.pi/agent/settings.json at launch.";
        };

        rules = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.either lib.types.lines (lib.types.addCheck lib.types.path builtins.isPath)
          );
          default = null;
          description = "System prompt instructions or path to markdown file appended to pi.";
        };

        skills = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "List of skill directories passed to pi via --skill.";
        };
      };

      config = lib.mkIf cfg.enable {
        programs.pi.coding-agent = {
          enable = true;
          package = lib.mkDefault effectivePackage;
          jail.enable = lib.mkIf cfg.jail.enable (lib.mkDefault true);
          settings = lib.mkDefault (defaultSettings // cfg.settings);
          rules = lib.mkIf (cfg.rules != null) (lib.mkDefault cfg.rules);
          skills = lib.mkIf (cfg.skills != [ ]) (lib.mkDefault cfg.skills);
          extensions = lib.mkIf (allExtensions != [ ]) (lib.mkDefault allExtensions);
        };

        # Binary cache for faster builds & substituters
        nix.settings = {
          substituters = [ "https://pi.cachix.org" ];
          trusted-public-keys = [
            "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
          ];
        };
      };
    };
}
