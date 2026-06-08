{ lib, ... }:

{
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        powersave = lib.mkDefault false;
        macAddress = "stable";
      };
      dns = "systemd-resolved";
    };
    wireless.iwd.settings.General.Country = "NZ";

    firewall = {
      enable = true;
      allowedTCPPorts = [ 53317 ]; # LocalSend
      allowedUDPPorts = [ 53317 ]; # LocalSend
    };

    enableIPv6 = true;
  };

  systemd.services.NetworkManager-wait-online.enable = lib.mkDefault false;

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111";
        FallbackDNS = "8.8.8.8#dns.google 8.8.4.4#dns.google";
        DNSSEC = "allow-downgrade";
        DNSOverTLS = "opportunistic";
        Domains = [ "~." ];
      };
    };
  };
}
