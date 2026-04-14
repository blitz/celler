{ ... }:
{
  flake.herculesCI.ciSystems = [
    "x86_64-linux"

    # Disabled for lack of CI resources.
    # "aarch64-linux"
  ];
}
