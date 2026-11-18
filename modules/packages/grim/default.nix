# grim 1.5.0 rounds the shared-memory stride up to a multiple of 4 bytes only,
# which breaks window capture on MangoWC: the compositor announces a 24-bit
# capture format and rejects the resulting stride, so `grim -T` exits with
# "Invalid stride". Upstream fixed it after 1.5.0 (grim commit 0a2c5c9, "Always
# extend stride to be a multiple of the bpp"); drop this override when a release
# contains it.
_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.grim = pkgs.grim.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./stride.patch ];
      });
    };
}
