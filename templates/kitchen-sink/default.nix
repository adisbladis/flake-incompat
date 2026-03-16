{ nixpkgs }:
let
  inherit (nixpkgs) lib;
in
{
  packages =
    { pkgs }:
    {
      inherit (pkgs) hello;
    };

  devShells =
    { pkgs }:
    {
      default = pkgs.mkShell {
        packages = [ ];
      };
    };

  overlays = {
    default = _: _: { };
  };

  formatter = { pkgs }: pkgs.hello;

  nixosConfigurations = {
    my-desktop = lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ }: { })
      ];
    };
  };

  nixosModules."my-module" =
    { config, ... }:
    {
      options = { };
      config = { };
    };

  legacyPackages =
    { pkgs, self' }:
    {
      devhell = self'.devShells.default;
      inherit (pkgs) python3;
    };
}
