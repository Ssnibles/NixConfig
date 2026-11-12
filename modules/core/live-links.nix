# Live config symlinks.
# Links from the NixConfig checkout into the home directory. They point at the
# working tree, so edits take effect without a rebuild. Consumers register an
# entry in nixos.liveLinks and this module writes one activation script.
{ ... }:
{
  nixos.modules.shared =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.nixos.liveLinks;

      # Quote a value for the activation script.
      q = lib.escapeShellArg;

      # A missing source is a config error, so fail the activation loudly
      # instead of creating dangling links.
      requireSource = link: ''
        if [ ! -e ${q link.source} ]; then
          echo "live-links: source missing: ${q link.source}" >&2
          exit 1
        fi
      '';

      # Link one file and replace anything already at the target.
      fileLink =
        link:
        let
          home = config.users.users.${link.user}.home;
          target = "${home}/${link.target}";
          owner = "${link.user}:${config.users.users.${link.user}.group}";
        in
        ''
          ${requireSource link}
          # A real directory may hold user data, so never delete one. Only a
          # link or a file is replaced.
          if [ -d ${q target} ] && [ ! -L ${q target} ]; then
            echo "live-links: refusing to replace directory: ${q target}" >&2
            exit 1
          fi
          mkdir -p ${q (builtins.dirOf target)}
          rm -f ${q target}
          ln -sfn ${q link.source} ${q target}
          chown -h ${q owner} ${q target} || true
        '';

      # Link every entry of a directory into the target, then remove stale links
      # that point back into the source. Links managed by Hjem are left alone.
      contentsLink =
        link:
        let
          home = config.users.users.${link.user}.home;
          target = "${home}/${link.target}";
          owner = "${link.user}:${config.users.users.${link.user}.group}";
        in
        ''
          ${requireSource link}
          # Remove a directory symlink left by an older activation script, so
          # the links below are not written through it into the source tree.
          if [ -L ${q target} ]; then rm -f ${q target}; fi
          mkdir -p ${q target}
          chown ${q owner} ${q target} || true
          for entry in ${q link.source}/*; do
            [ -e "$entry" ] || continue
            base=$(basename "$entry")
            ln -sfn "$entry" ${q target}/"$base"
            chown -h ${q owner} ${q target}/"$base" || true
          done
          for existing in ${q target}/*; do
            [ -L "$existing" ] || continue
            case "$(readlink "$existing")" in
              ${q link.source}/*)
                [ -e "$(readlink "$existing")" ] || rm -f "$existing"
                ;;
            esac
          done
        '';

      render = _: link: if link.contents then contentsLink link else fileLink link;
    in
    {
      options.nixos.configRepo = lib.mkOption {
        type = lib.types.str;
        default = "${config.users.users.${config.username}.home}/NixConfig";
        description = "Absolute path of the mutable NixConfig checkout that live symlinks point at.";
      };

      options.nixos.liveLinks = lib.mkOption {
        default = { };
        description = ''
          Symlinks from the config checkout into users' homes, recreated on every
          activation. Key by a unique name.
        '';
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              source = lib.mkOption {
                type = lib.types.str;
                description = "Absolute path of the link source (normally under nixos.configRepo).";
              };
              target = lib.mkOption {
                type = lib.types.str;
                description = "Home-relative path of the link to create.";
              };
              user = lib.mkOption {
                type = lib.types.str;
                default = config.username;
                defaultText = lib.literalExpression "config.username";
                description = "User whose home the link is created in.";
              };
              contents = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Link the entries of `source` into the `target` directory instead of linking `source` itself.";
              };
            };
          }
        );
      };

      config = lib.mkIf (cfg != { }) {
        system.activationScripts.live-links = lib.concatStringsSep "\n" (lib.mapAttrsToList render cfg);
      };
    };
}
