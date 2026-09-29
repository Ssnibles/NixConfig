# =============================================================================
# Uni Notes — Typst Theme
# =============================================================================
# The canonical shared Typst theme for the notes repositories lives here
# (`theme.typ`). The `typst-snippets` skill bundles a copy for reference, and
# notes bootstrap it with `uni-notes-theme`, which copies it into
# `templates/theme.typ` in the current notes repo.
# =============================================================================
{ ... }:
let
  mkUniNotesTheme =
    pkgs:
    pkgs.writeShellScriptBin "uni-notes-theme" ''
      set -euo pipefail

      theme="${./theme.typ}"
      target="templates/theme.typ"

      case "''${1:-}" in
        -h|--help)
          echo "uni-notes-theme — bootstrap the shared Typst theme in a notes repo"
          echo
          echo "Usage:"
          echo "  uni-notes-theme [target]   copy the theme to <target>"
          echo "                             (default: templates/theme.typ)"
          echo "  uni-notes-theme --check    fail if the repo copy is missing/out of date"
          ;;
        --check)
          if [ ! -f "$target" ]; then
            echo "uni-notes-theme: $target is missing; run 'uni-notes-theme'" >&2
            exit 1
          fi
          if ${pkgs.diffutils}/bin/cmp -s "$theme" "$target"; then
            echo "uni-notes-theme: $target is up to date"
          else
            echo "uni-notes-theme: $target is out of date; run 'uni-notes-theme'" >&2
            exit 1
          fi
          ;;
        *)
          if [ -n "''${1:-}" ]; then target="$1"; fi
          ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$target")"
          ${pkgs.coreutils}/bin/rm -f "$target"
          ${pkgs.coreutils}/bin/install -m 0644 "$theme" "$target"
          echo "uni-notes-theme: wrote $target"
          ;;
      esac
    '';
in
{
  perSystem = { pkgs, ... }: {
    packages.uni-notes-theme = mkUniNotesTheme pkgs;
  };

  nixos.modules.shared =
    { pkgs, ... }:
    {
      environment.systemPackages = [ (mkUniNotesTheme pkgs) ];
    };
}
