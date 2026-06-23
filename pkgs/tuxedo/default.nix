{ inputs
, rustPlatform
,
}:

rustPlatform.buildRustPackage {
  pname = "tuxedo";
  version = "unstable-2026-06-13";
  src = inputs.tuxedo;
  cargoLock.lockFile = "${inputs.tuxedo}/Cargo.lock";
  doCheck = false;
}
