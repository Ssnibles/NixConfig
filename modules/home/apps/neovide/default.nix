{ ... }:
{
  programs.nvf.settings.vim.globals = {
    neovide_font_family = "JetBrainsMono Nerd Font";
    neovide_font_size = 12;

    neovide_padding_top = 20;
    neovide_padding_bottom = 20;
    neovide_padding_left = 20;
    neovide_padding_right = 20;

    neovide_refresh_rate = 60;
    neovide_idle = true;
    neovide_vsync = true;
    neovide_cursor_vfx_mode = "";
    neovide_cursor_animation_length = 0.0;
    neovide_scroll_animation_length = 0.08;
    neovide_floating_blur = false;

    neovide_confirm_quit = true;
    neovide_remember_window_size = true;
  };
}
