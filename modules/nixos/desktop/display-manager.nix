{ pkgs, ... }:

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

  # Fix gnome-keyring not unlocking with ly:
  # ly doesn't properly pass PAM_AUTHTOK to pam_gnome_keyring.so.
  # Using try_first_pass makes it attempt to use the password from
  # the PAM stack, falling back to a separate prompt if needed.
  security.pam.services.ly.rules.auth.gnome_keyring.settings = {
    use_authtok = false;
    try_first_pass = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };

  services.gnome.gnome-keyring.enable = true;
}
