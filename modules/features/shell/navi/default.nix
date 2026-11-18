_: {
  flake.nixosModules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      inherit (pkgs) lib;

      home = config.users.users.${config.username}.home;
      naviDir = "${home}/.config/navi";
      cheatsDir = "${naviDir}/cheats";

      # Cheats are Nix data rendered to navi cheat files. Placeholders written
      # as <name=default> become navi variables with a suggestion line, so the
      # old defaults still appear in the picker. Add snippets here and rebuild.
      mk = description: command: tag: {
        inherit description command tag;
        extraSuggestions = [ ];
      };

      # Like mk, but with extra navi suggestion lines. Used when one default
      # depends on another, such as a binary name following the package.
      mkSuggestions = extraSuggestions: description: command: tag: {
        inherit
          description
          command
          tag
          extraSuggestions
          ;
      };

      # Split a command on <...> placeholders. A placeholder is returned as a
      # one element list and literal text as a string.
      splitOnVars = command: builtins.split "<([^>]*)>" command;
      varInner = m: builtins.elemAt m 0;

      # Parse name=default into a name and default. A bare name has no default.
      parseVar =
        inner:
        let
          m = builtins.match "([^=]*)=(.*)" inner;
        in
        if m == null then
          {
            name = inner;
            default = null;
          }
        else
          {
            name = builtins.elemAt m 0;
            default = builtins.elemAt m 1;
          };

      # Rewrite <name=default> to navi's <name>.
      renderCommand =
        command:
        lib.concatStringsSep "" (
          map (part: if builtins.isList part then "<${(parseVar (varInner part)).name}>" else part) (
            splitOnVars command
          )
        );

      # Unique variables in order, each with its default.
      paramVars =
        command:
        let
          matches = builtins.filter builtins.isList (splitOnVars command);
          vars = map (m: parseVar (varInner m)) matches;
          names = lib.unique (map (v: v.name) vars);
        in
        map (
          n:
          lib.findFirst (v: v.name == n) {
            name = n;
            default = null;
          } vars
        ) names;

      # Suggestion line for a variable, or null when there is no default.
      suggestion =
        v:
        if v.default == null then
          null
        else if lib.hasPrefix "$(" v.default && lib.hasSuffix ")" v.default then
          # The old default was a shell command, so let navi run it.
          "$ ${v.name}: ${lib.removeSuffix ")" (lib.removePrefix "$(" v.default)}"
        else
          "$ ${v.name}: echo ${lib.escapeShellArg v.default}";

      renderCheat =
        s:
        let
          suggestions =
            builtins.filter (x: x != null) (map suggestion (paramVars s.command)) ++ s.extraSuggestions;
        in
        lib.concatStringsSep "\n" (
          [
            "% ${lib.concatStringsSep ", " s.tag}"
            ""
            "# ${s.description}"
            (renderCommand s.command)
          ]
          ++ suggestions
          ++ [ "" ]
        );

      renderCheats = snippets: lib.concatMapStringsSep "\n" renderCheat snippets;

      snippetData = import ./_snippets.nix {
        inherit mk mkSuggestions;
      };
      inherit (snippetData) core snippets;

      allSnippets = {
        inherit core;
      }
      // snippets;

      cheatFiles = lib.mapAttrs' (
        name: value:
        lib.nameValuePair ".config/navi/cheats/${name}.cheat" {
          text = renderCheats value;
        }
      ) allSnippets;

      # fzf preview: the command wrapped to the pane width, then the
      # description in dim text. Padding to the bottom overflows once the
      # command wraps, so the text flows from the top instead.
      previewScript = pkgs.writeShellScript "navi-preview" ''
        export PATH=${lib.makeBinPath [ pkgs.coreutils ]}:$PATH

        comment=$1
        snippet=$2
        cols=''${FZF_PREVIEW_COLUMNS:-80}

        snippet=$(printf '%s' "$snippet" | tr '\025' ' ')
        comment=$(printf '%s' "$comment" | tr '\025' ' ')

        body=$(printf '%s\n' "$snippet" | fold -s -w "$cols")
        footer=$(printf '%s\n' "$comment" | fold -s -w "$cols")

        printf '%s\n' "$body"
        if [ -n "$comment" ]; then
          printf '\n\033[2m%s\033[0m\n' "$footer"
        fi
      '';
    in
    {
      environment.systemPackages = [ pkgs.navi ];

      hjem.users."${config.username}" = {
        files = {
          ".config/navi/config.yaml" = {
            text = ''
              cheats:
                paths:
                  - ${cheatsDir}
              finder:
                command: fzf
                # Navi pads and truncates fields 1-3; fields 4-6 are the full
                # tags, description and command. Show the full ones so
                # commands keep their width. Ctrl-/ toggles the preview.
                overrides: >-
                  --with-nth '6,4,5'
                  --no-hscroll
                  --height=100%
                  --preview '${previewScript} {5} {6}'
                  --preview-window 'down,32%,wrap,border-top,noinfo'
                  --bind 'ctrl-/:toggle-preview'
                # A lone suggestion is accepted without asking when
                # --select-1 is on, so the nix shell prompts never appear.
                # Drop the empty list chrome to keep the prompt one form.
                overrides_var: >-
                  --no-select-1
                  --no-info
                  --no-separator
                  --pointer=' '
                  --height=70%
                  --preview-window=noinfo
                  --preview-border=none
            '';
          };
        }
        // cheatFiles;
      };
    };
}
