# OpenSSH server.
# Password login is disabled. sshd is only reachable over trusted interfaces
# such as tailscale0.
{ ... }:
{
  nixos.modules.shared =
    { config, ... }:
    {
      services.openssh = {
        enable = true;
        openFirewall = false;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          AllowUsers = [ config.username ];
          MaxAuthTries = 3;
          LoginGraceTime = 20;
        };
      };

      # Installed declaratively instead of writing authorized_keys in install.sh.
      users.users.${config.username}.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIML005i/5k2e1dOrzqZ5U2UIkv5bPluW85BViniWc/PJ"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAXZTaFjH5NB2JNLE1Us7aw3fXeuhIQRWehNwJas7yab"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKcruGwn5BHF8YXZwbbzd7P4ddQw6D/S1uHIg/1Dy1BI"
      ];
    };
}
