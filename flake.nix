{
  description = "NixOS configuration for the CMU TLI server fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # External NixOS modules.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fleet-owned source repositories.
    cmu-web-kilt = {
      url = "github:cmu-web/cmu-web-kilt/0.6.7";
      flake = false;
    };

    # Jekyll & Plaid's docs site, built by the repository's release workflow
    # (a Jekyll build with the github-pages gem, as GitHub Pages does).
    jekyll-and-plaid-site = {
      url = "https://github.com/cmu-web/cmu-web-jekyll-and-plaid/releases/download/0.2.1/site.tar.gz";
      flake = false;
    };

    cmutli-dashboards = {
      url = "github:CMUTLI/cmutli-dashboards";
      flake = false;
    };

    cmutli-fleet-secrets = {
      url = "git+ssh://git@github.com/CMUTLI/cmutli-fleet-secrets.git";
      flake = false;
    };

    cmutli-fleet-vendor = {
      url = "git+ssh://git@github.com/CMUTLI/cmutli-fleet-vendor.git?lfs=1";
      flake = false;
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      sops-nix,
      disko,
      home-manager,
      quadlet-nix,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      hostSystem = "x86_64-linux";
      mkHost =
        hostModule: diskModule:
        nixpkgs.lib.nixosSystem {
          system = hostSystem;
          specialArgs = { inherit inputs; };
          modules = [
            ./modules/base.nix
            diskModule
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            hostModule
            quadlet-nix.nixosModules.quadlet
            sops-nix.nixosModules.sops
          ];
        };
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              age
              git
              sops
            ];
          };
        }
      );

      # #### Fleet hosts ####
      # Add new entries below in alphabetical order.

      nixosConfigurations."keys-01.tli.cmu.edu" =
        mkHost ./hosts/keys-01.tli.cmu.edu/configuration.nix ./hosts/keys-01.tli.cmu.edu/disko.nix;

      nixosConfigurations."ops-01.tli.cmu.edu" =
        mkHost ./hosts/ops-01.tli.cmu.edu/configuration.nix ./hosts/ops-01.tli.cmu.edu/disko.nix;

      nixosConfigurations."programs-01.eberly.cmu.edu" =
        mkHost ./hosts/programs-01.eberly.cmu.edu/configuration.nix ./hosts/programs-01.eberly.cmu.edu/disko.nix;

      nixosConfigurations."syllabus-registry-01.tli.cmu.edu" =
        mkHost ./hosts/syllabus-registry-01.tli.cmu.edu/configuration.nix ./hosts/syllabus-registry-01.tli.cmu.edu/disko.nix;

      nixosConfigurations."www-01.tli.cmu.edu" =
        mkHost ./hosts/www-01.tli.cmu.edu/configuration.nix ./hosts/www-01.tli.cmu.edu/disko.nix;
    };
}
