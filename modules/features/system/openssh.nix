# =============================================================================
# OpenSSH Server Feature
# =============================================================================
# Key-only SSH server. The firewall is left closed so sshd is only reachable
# over trusted interfaces (tailscale0), which is where the authorized keys are
# meant to be used.
# =============================================================================
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

      # Declarative replacement for install.sh's imperative
      # ~/.ssh/authorized_keys write. Mirrored from github.com/Ssnibles.keys.
      users.users.${config.username}.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIML005i/5k2e1dOrzqZ5U2UIkv5bPluW85BViniWc/PJ"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAXZTaFjH5NB2JNLE1Us7aw3fXeuhIQRWehNwJas7yab"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKcruGwn5BHF8YXZwbbzd7P4ddQw6D/S1uHIg/1Dy1BI"
      ];
    };
}
