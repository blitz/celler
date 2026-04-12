# For distribution from this repository as well as CI, we use Crane to build
# Celler.

{ stdenv
, lib
, buildPackages
, craneLib
, rust
, runCommand
, writeClosure
, pkg-config
, installShellFiles
, jq

, nix
, boost
, libarchive

, extraPackageArgs ? {}
}:

let
  version = "0.1.0";

  ignoredPaths = [
    ".ci"
    ".github"
    "book"
    "flake"
    "integration-tests"
    "nixos"
    "target"
  ];

  src = lib.cleanSourceWith {
    filter = name: type: !(type == "directory" && builtins.elem (baseNameOf name) ignoredPaths);
    src = lib.cleanSource ./.;
  };

  nativeBuildInputs = [
    pkg-config
    installShellFiles
  ];

  buildInputs = [
    nix boost
    libarchive
  ];

  crossArgs = let
    rustTargetSpec = rust.toRustTargetSpec stdenv.hostPlatform;
    rustTargetSpecEnv = lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] rustTargetSpec);
  in lib.optionalAttrs (stdenv.hostPlatform != stdenv.buildPlatform) {
    depsBuildBuild = [ buildPackages.stdenv.cc ];

    CARGO_BUILD_TARGET = rustTargetSpec;
    "CARGO_TARGET_${rustTargetSpecEnv}_LINKER" = "${stdenv.cc.targetPrefix}cc";
  };

  extraArgs = crossArgs // extraPackageArgs;

  cargoArtifacts = craneLib.buildDepsOnly ({
    pname = "celler";
    inherit src version nativeBuildInputs buildInputs;
  } // extraArgs);

  mkCeller = {
    packages,
  }: let
    cargoPackageArgs = map (p: "-p ${p}") packages;
  in craneLib.buildPackage ({
    pname = "celler";
    inherit src version nativeBuildInputs buildInputs cargoArtifacts;

    CELLER_DISTRIBUTOR = "celler";

    # See comment in `celler-tests`
    doCheck = false;

    cargoExtraArgs = lib.concatStringsSep " " cargoPackageArgs;

    postInstall = lib.optionalString (stdenv.hostPlatform == stdenv.buildPlatform) ''
      if [[ -f $out/bin/celler ]]; then
        installShellCompletion --cmd celler \
          --bash <($out/bin/celler gen-completions bash) \
          --zsh <($out/bin/celler gen-completions zsh) \
          --fish <($out/bin/celler gen-completions fish)
      fi
    '';

    meta = with lib; {
      description = "Multi-tenant Nix binary cache system";
      homepage = "https://github.com/blitz/celler";
      license = licenses.asl20;
      maintainers = with maintainers; [ blitz ];
      platforms = platforms.linux ++ platforms.darwin;
      mainProgram = "celler";
    };

    passthru = {
      inherit nix;
    };
  } // extraArgs);

  celler = mkCeller {
    packages = ["attic-client" "attic-server"];
  };

  # Celler interacts with Nix directly and its tests require trusted-user access
  # to nix-daemon to import NARs, which is not possible in the build sandbox.
  # In the CI pipeline, we build the test executable inside the sandbox, then
  # run it outside.
  celler-tests = craneLib.mkCargoDerivation ({
    pname = "celler-tests";

    inherit src version buildInputs cargoArtifacts;

    nativeBuildInputs = nativeBuildInputs ++ [ jq ];

    doCheck = true;

    buildPhaseCargoCommand = "";
    checkPhaseCargoCommand = "cargoWithProfile test --no-run --message-format=json >cargo-test.json";
    doInstallCargoArtifacts = false;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      jq -r 'select(.reason == "compiler-artifact" and .target.test and .executable) | .executable' <cargo-test.json | \
        xargs -I _ cp _ $out/bin

      runHook postInstall
    '';
  } // extraArgs);
in {
  inherit cargoArtifacts celler celler-tests;
}
