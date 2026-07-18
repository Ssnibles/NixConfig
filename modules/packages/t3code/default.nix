{ self, inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      version = "2026-04-02";

      src = pkgs.fetchFromGitHub {
        owner = "coygeek";
        repo = "2026-03-31-t3-opencode";
        rev = "24a542c6f8731476f333298662f273c164ff2446";
        hash = "sha256-Z4BhkHdH9iEW45lstyklKwzQ1/qDXNJN8pdXlfoZYaY=";
      };

      nodeModules = pkgs.stdenvNoCC.mkDerivation {
        pname = "t3code-node_modules";
        inherit version src;

        strictDeps = true;

        nativeBuildInputs = [
          pkgs.bun
          pkgs.nodejs
          pkgs.writableTmpDirAsHomeHook
        ];

        dontConfigure = true;
        dontFixup = true;

        postPatch = ''
          for packageJson in \
            packages/contracts/package.json \
            packages/shared/package.json
          do
            substituteInPlace "$packageJson" \
              --replace-fail '"prepare": "effect-language-service patch",' '"prepare": "true",'
          done
        '';

        buildPhase = ''
          runHook preBuild

          bun install \
            --ignore-scripts \
            --no-progress \
            --frozen-lockfile \
            --filter ./apps/server \
            --filter ./apps/web \
            --filter ./packages/contracts \
            --filter ./packages/shared

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p "$out"
          find . -type d -name node_modules \
            -exec cp -R --parents {} "$out" \;

          runHook postInstall
        '';

        outputHash = "sha256-YVoHCTiufVFc3G2kJT2Li+JSnht54ZgtjtnJdsfrgO0=";
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      };
    in
    {
      packages.t3code = pkgs.stdenv.mkDerivation {
        pname = "t3code";
        inherit version src;

        strictDeps = true;

        nativeBuildInputs = [
          pkgs.bun
          pkgs.makeBinaryWrapper
          pkgs.node-gyp
          pkgs.nodejs
          pkgs.python3
          pkgs.writableTmpDirAsHomeHook
        ];

        configurePhase = ''
          runHook preConfigure

          cp -R ${nodeModules}/. .

          chmod -R u+rwX node_modules
          patchShebangs node_modules

          cd node_modules/.bun/node-pty@*/node_modules/node-pty
          node-gyp rebuild
          node scripts/post-install.js
          cd "$NIX_BUILD_TOP/$sourceRoot"

          runHook postConfigure
        '';

        buildPhase = ''
          runHook preBuild

          bun run --cwd apps/web build
          bun run --cwd apps/server build

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p "$out/libexec/t3code/apps/server"
          cp -R --no-preserve=mode node_modules "$out/libexec/t3code/"
          cp -R --no-preserve=mode apps/server/{node_modules,dist} \
            "$out/libexec/t3code/apps/server/"

          rm -f \
            "$out/libexec/t3code/apps/server/node_modules/@t3tools/contracts" \
            "$out/libexec/t3code/apps/server/node_modules/@t3tools/shared" \
            "$out/libexec/t3code/apps/server/node_modules/@t3tools/web"

          for wsDir in "$out"/libexec/t3code/node_modules/.bun/ws@*/node_modules/ws; do
            ln -s "$wsDir" \
              "$out/libexec/t3code/apps/server/node_modules/ws"
            break
          done

          makeWrapper ${lib.getExe pkgs.nodejs} "$out/bin/t3" \
            --add-flags "$out/libexec/t3code/apps/server/dist/index.mjs"

          runHook postInstall
        '';

        meta = {
          description = "T3 Code with OpenCode";
          homepage = "https://t3.codes";
          license = lib.licenses.mit;
          mainProgram = "t3";
        };
      };
    };
}
