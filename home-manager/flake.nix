{
  description = "Home Manager configuration of feniix";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations."feniix" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [ ./home.nix ];

        # Shared values accessible to every module via its function signature.
        # New modules just write `{ ..., dotfilesDir, ... }:` to use them.
        extraSpecialArgs = {
          inherit inputs;
          dotfilesDir = "/Users/feniix/dotfiles";
        };
      };
    };
}
