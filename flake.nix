{
  description = "NixOS configuration for the CMU TLI server fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cmutli-fleet-secrets = {
      url = "git+ssh://git@github.com/CMUTLI/cmutli-fleet-secrets.git";
      flake = false;
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
  };

  outputs = inputs@{ nixpkgs, sops-nix, disko, home-manager, quadlet-nix, ... }:
    let
      mkHost = hostModule: diskModule: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          hostModule
          diskModule
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          quadlet-nix.nixosModules.quadlet
        ];
      };
    in {
    # Keyed by FQDN, not short hostname: short hostnames are not unique
    # across domains in this fleet (for example a future www-01 could
    # exist under core.cmu.edu, eberly.cmu.edu, and tli.cmu.edu at once).
    nixosConfigurations."syllabus-registry-01.tli.cmu.edu" = mkHost
      ./hosts/syllabus-registry-01.tli.cmu.edu/configuration.nix
      ./hosts/syllabus-registry-01.tli.cmu.edu/disko.nix;

    nixosConfigurations."programs-01.eberly.cmu.edu" = mkHost
      ./hosts/programs-01.eberly.cmu.edu/configuration.nix
      ./hosts/programs-01.eberly.cmu.edu/disko.nix;

    nixosConfigurations."ops-01.tli.cmu.edu" = mkHost
      ./hosts/ops-01.tli.cmu.edu/configuration.nix
      ./hosts/ops-01.tli.cmu.edu/disko.nix;
  };
}
