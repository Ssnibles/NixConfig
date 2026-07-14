{
  security.pam.services.quickshell = {
    enable = true;
    text = ''
      auth     include system-auth
      account  include system-auth
      password include system-auth
    '';
  };
}
