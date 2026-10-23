# Pi coding agent.
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

      # Typst packages used by the shared theme. Pinning them lets the skill
      # examples compile offline during the build.
      typstPreviewPackages = pkgs.runCommand "pi-skill-typst-packages" { } ''
        mkdir -p $out/preview
        extract() {
          mkdir -p "$out/preview/$2/$3"
          tar -xzf "$1" -C "$out/preview/$2/$3"
        }
        extract ${
          pkgs.fetchurl {
            url = "https://packages.typst.org/preview/cetz-0.5.2.tar.gz";
            sha256 = "0gzjj9r1kh88awdpf6cpvg5a116jj6kfy4ascrp4rq2a26889kvp";
          }
        } cetz 0.5.2
        extract ${
          pkgs.fetchurl {
            url = "https://packages.typst.org/preview/oxifmt-1.0.0.tar.gz";
            sha256 = "0ksrb7ysd3m9bxv10mwf67wmy8m4c1rkrc5j7kn405yhibya25vx";
          }
        } oxifmt 1.0.0
        extract ${
          pkgs.fetchurl {
            url = "https://packages.typst.org/preview/zap-0.6.0.tar.gz";
            sha256 = "1682mh2rzxcf20dsazyvjjwignc49dg4h94swdj0gvy4lh4g9b9f";
          }
        } zap 0.6.0
        extract ${
          pkgs.fetchurl {
            url = "https://packages.typst.org/preview/mmdr-0.2.2.tar.gz";
            sha256 = "11nck1gxsdlsccy8j362d84pnrxs16r92h90jqws4sdjm3l58yz8";
          }
        } mmdr 0.2.2

        # Fail if a package layout changes.
        for pkg in cetz/0.5.2 oxifmt/1.0.0 zap/0.6.0 mmdr/0.2.2; do
          test -f "$out/preview/$pkg/typst.toml" || {
            echo "typst package $pkg missing its typst.toml" >&2
            exit 1
          }
        done
      '';

      # Bundle a skill, check its SKILL.md, and compile its examples. A broken
      # example or a bad skill fails the build.
      mkSkill =
        name: src:
        pkgs.runCommand "pi-skill-${name}"
          {
            nativeBuildInputs = [ pkgs.typst ];
          }
          ''
            mkdir -p $out
            cp -r ${src}/. $out/
            export HOME=$(mktemp -d)
            export XDG_CACHE_HOME=$HOME/.cache
            bash ${./pi-agent/skills/check-skills.sh} \
              $out --expect ${name} --compile \
              --theme ${../../packages/uni-notes/theme.typ} \
              --package-path ${typstPreviewPackages} \
              --font-path ${pkgs.dejavu_fonts}/share/fonts/truetype
          '';

      # The Typst snippet skill. The LuaSnip source lives in the Neovim config,
      # so copy it in at build time to keep the skill in sync.
      typstSnippetsSkill = pkgs.runCommand "pi-skill-typst-snippets" { } ''
        mkdir -p $out/references
        install -m 0444 ${./pi-agent/skills/typst-snippets/SKILL.md} $out/SKILL.md
        install -m 0444 ${./pi-agent/skills/typst-snippets/references/document-conventions.md} $out/references/document-conventions.md
        install -m 0444 ${./pi-agent/skills/typst-snippets/references/diagrams.md} $out/references/diagrams.md
        install -m 0444 ${./pi-agent/skills/typst-snippets/references/math.md} $out/references/math.md
        install -m 0444 ${./pi-agent/skills/typst-snippets/references/page-preamble.typ} $out/references/page-preamble.typ
        install -m 0444 ${../../packages/uni-notes/theme.typ} $out/references/theme.typ
        install -m 0444 ${./pi-agent/skills/typst-snippets/references/example.typ} $out/references/example.typ
        install -m 0444 ${../nvim-src/lua/snippets/typst.lua} $out/references/typst.lua

        # Fail if the theme, page snippet, and page-preamble.typ drift.
        bash ${./pi-agent/skills/typst-snippets/check-sync.sh} $out/references

        # Check the skill frontmatter.
        bash ${./pi-agent/skills/check-skills.sh} $out --expect typst-snippets
      '';

      bundledSkills =
        lib.optional cfg.baseConventions (mkSkill "base-conventions" ./pi-agent/skills/base-conventions)
        ++ lib.optional cfg.programmingConventions (
          mkSkill "programming-conventions" ./pi-agent/skills/programming-conventions
        )
        ++ lib.optional cfg.typstSnippets typstSnippetsSkill
        ++ lib.optional cfg.lectureNotes (mkSkill "lecture-notes" ./pi-agent/skills/lecture-notes)
        ++ lib.optional cfg.testNotes (mkSkill "test-notes" ./pi-agent/skills/test-notes)
        ++ lib.optional cfg.labNotes (mkSkill "lab-notes" ./pi-agent/skills/lab-notes)
        ++ lib.optional cfg.assignmentReport (
          mkSkill "assignment-report" ./pi-agent/skills/assignment-report
        )
        ++ lib.optional cfg.revisionSheets (mkSkill "revision-sheets" ./pi-agent/skills/revision-sheets);

      defaultSettings = {
        inherit (cfg) defaultProvider defaultModel;
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

        # Built-in Extension Toggles
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
          description = "Enable subagent extension (delegate tasks to specialised subagents with isolated context).";
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

        baseConventions = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Bundle the base-conventions skill. It sets British English and
            short, plain comments for every task.
          '';
        };

        programmingConventions = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Bundle the programming-conventions skill. It sets the rules for
            any code, configuration, or refactoring work.
          '';
        };

        typstSnippets = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Bundle the typst-snippets skill. It teaches pi the Typst
            conventions from the Neovim snippet library.
          '';
        };

        lectureNotes = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Bundle the lecture-notes skill, which turns lecture slides or
            recordings into high-yield study notes instead of re-typed copies
            of the slides.
          '';
        };

        testNotes = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Bundle the test-notes skill, which turns past tests, exams and
            practice papers into worked study guides that answer every question
            with the correct answer and the reasoning.
          '';
        };

        labNotes = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Bundle the lab-notes skill, which turns lab sessions, practicals
            and exercises into notes that explain the method, results and why
            they turned out that way.
          '';
        };

        assignmentReport = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Bundle the assignment-report skill, which turns briefs and
            specifications into structured write-ups that address every
            requirement and mark-scheme item.
          '';
        };

        revisionSheets = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Bundle the revision-sheets skill, which compresses a course or
            topic into dense one-page revision sheets and active-recall
            question banks.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        programs.pi.coding-agent = {
          enable = true;
          package = lib.mkDefault effectivePackage;
          jail.enable = lib.mkIf cfg.jail.enable (lib.mkDefault true);
          settings = lib.mkDefault (defaultSettings // cfg.settings);
          rules = lib.mkIf (cfg.rules != null) (lib.mkDefault cfg.rules);
          skills = lib.mkIf (cfg.skills != [ ] || bundledSkills != [ ]) (
            lib.mkDefault (bundledSkills ++ cfg.skills)
          );
          extensions = lib.mkIf (allExtensions != [ ]) (lib.mkDefault allExtensions);
        };

        # Faster builds from binary caches.
        nix.settings = {
          substituters = [ "https://pi.cachix.org" ];
          trusted-public-keys = [
            "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
          ];
        };
      };
    };
}
