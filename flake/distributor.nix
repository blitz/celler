{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  options = {
    celler.distributor = mkOption {
      type = types.str;
      default = "dev";
    };
  };
}
