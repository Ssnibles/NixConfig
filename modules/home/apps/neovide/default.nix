{
  config,
  lib,
  pkgs,
  ...
}:
let
  c =
    (import ../../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; })
    .withHash;
in
{
  programs.nvf.settings.vim.globals = {
    # ── Font & typography ── match Foot terminal config ────────────────────
    neovide_font_family = "JetBrainsMono Nerd Font";
    neovide_font_size = 12;

    # ── Padding ── match Foot pad=20x20 ───────────────────────────────────
    neovide_padding_top = 20;
    neovide_padding_bottom = 20;
    neovide_padding_left = 20;
    neovide_padding_right = 20;

    # ── Performance ── lower resource consumption ─────────────────────────
    neovide_refresh_rate = 60;
    neovide_idle = true;
    neovide_vsync = true;
    neovide_cursor_vfx_mode = "";
    neovide_cursor_animation_length = 0.0;
    neovide_scroll_animation_length = 0.08;
    neovide_floating_blur = false;

    # ── UX ────────────────────────────────────────────────────────────────
    neovide_confirm_quit = true;
    neovide_remember_window_size = true;
  };
}
