{ ... }:

{
  services.displayManager.ly = {
    enable = true;
    settings = {
      box_title = "Welcome";
      clock = "%a %d %b  %H:%M";
      text_in_center = true;
      box_position_v = 0.50;
      input_len = 38;
      default_input = "login";
      hide_key_hints = true;
      hide_keyboard_locks = true;
      hide_version_string = true;
      animation = "none";
      blank_box = true;
    };
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.ly.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
}
