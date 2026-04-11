let
  flake = import ./flake-compat.nix;
in flake.defaultNix.default.overrideAttrs (_: {
  passthru = {
    celler-client = flake.defaultNix.outputs.packages.${builtins.currentSystem}.celler-client;
    demo = flake.defaultNix.outputs.devShells.${builtins.currentSystem}.demo;
  };
})
