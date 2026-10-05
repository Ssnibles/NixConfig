# =============================================================================
# Live Config Symlinks
# =============================================================================
# Declarative registry of symlinks from the mutable NixConfig checkout into the
# user's home. Unlike Hjem (which only accepts store paths and is meant for
# immutable files), these links intentionally point at the working tree so
# edits take effect immediately, without a rebuild.
#
# Every consumer registers an entry in `nixos.liveLinks`; this module turns them
# into a single `system.activationScripts.live-links` script. Centralising the
# logic means one place to reason about ownership and ordering, instead of a
# dozen ad-hoc `ln -sfn`/`chown -R` snippets racing Hjem.
# =============================================================================
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

      # Shell-quote a value for inclusion in the activation script.
      q = lib.escapeShellArg;

      # One `file` link: replace whatever is at the target with a symlink.
      fileLink =
        link:
        let
          home = config.users.users.${link.user}.home;
          target = "${home}/${link.target}";
          owner = "${link.user}:${config.users.users.${link.user}.group}";
        in
        ''
          mkdir -p ${q (builtins.dirOf target)}
          rm -rf ${q target}
          ln -sfn ${q link.source} ${q target}
          chown -h ${q owner} ${q target} || true
        '';

      # One `contents` link: symlink every entry of the source directory into the
      # target directory, then prune stale links that point back into the source.
      # Only links whose resolved target lives under the source are removed, so
      # Hjem-managed store symlinks (e.g. Colours.qml) in the same directory are
      # left untouched.
      contentsLink =
        link:
        let
          home = config.users.users.${link.user}.home;
          target = "${home}/${link.target}";
          owner = "${link.user}:${config.users.users.${link.user}.group}";
        in
        ''
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
        default = "/home/${config.username}/NixConfig";
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
