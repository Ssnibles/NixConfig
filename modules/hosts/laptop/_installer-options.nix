{ lib, ... }:
{
  username = lib.mkForce "josh";
  networking.hostName = lib.mkForce "laptop";
}
