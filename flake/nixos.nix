{ config, ... }:
{
  flake.nixosModules = {
    cellerd = {
      imports = [
        ../nixos/cellerd.nix
      ];

      services.cellerd.useFlakeCompatOverlay = false;

      nixpkgs.overlays = [
        config.flake.overlays.default
      ];
    };
  };
}
