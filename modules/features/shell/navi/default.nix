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

      # fzf preview for the cheatsheet picker: the full command at the top,
      # the description on the last line of the pane.
      previewScript = pkgs.writeShellScript "navi-preview" ''
        export PATH=${lib.makeBinPath [ pkgs.coreutils ]}:$PATH

        comment=$1
        snippet=$2
        cols=''${FZF_PREVIEW_COLUMNS:-80}
        rows=''${FZF_PREVIEW_LINES:-20}

        snippet=$(printf '%s' "$snippet" | tr '\025' ' ')
        comment=$(printf '%s' "$comment" | tr '\025' ' ')

        body=$(printf '%s\n' "$snippet" | fold -s -w "$cols")
        footer=$(printf '%s\n' "$comment" | fold -s -w "$cols")

        body_lines=$(printf '%s\n' "$body" | wc -l)
        footer_lines=$(printf '%s\n' "$footer" | wc -l)
        pad=$((rows - body_lines - footer_lines))
        if [ "$pad" -lt 0 ]; then
          pad=0
        fi

        printf '%s\n' "$body"
        while [ "$pad" -gt 0 ]; do
          printf '\n'
          pad=$((pad - 1))
        done
        printf '\033[2m%s\033[0m\n' "$footer"
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
              # Navi orders its columns as tags, comment, command. Give the
              # command most of the width so it stays readable with the
              # preview open.
              style:
                tag:
                  width_percentage: 20
                  min_width: 12
                snippet:
                  width_percentage: 45
                  min_width: 30
              finder:
                command: fzf
                # Show the command first, then its tags. The description sits
                # at the bottom of the preview pane. fzf still searches every
                # column, so tags and descriptions keep filtering the list.
                # Ctrl-/ toggles the preview.
                overrides: --with-nth '3,1' --preview '${previewScript} {5} {6}' --preview-window 'right:55%' --bind 'ctrl-/:toggle-preview'
            '';
          };
        }
        // cheatFiles;
      };
    };
}
