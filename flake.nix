{
  description = "NixOS configuration for the CMU TLI server fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, sops-nix, disko, ... }: {
    # Keyed by FQDN, not short hostname: short hostnames are not unique
    # across domains in this fleet (for example a future www-01 could
    # exist under core.cmu.edu, eberly.cmu.edu, and tli.cmu.edu at once).
    nixosConfigurations."syllabus-registry-01.tli.cmu.edu" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/syllabus-registry-01.tli.cmu.edu/configuration.nix
        ./hosts/syllabus-registry-01.tli.cmu.edu/disko.nix
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
      ];
    };

    nixosConfigurations."seminars-03.eberly.cmu.edu" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/seminars-03.eberly.cmu.edu/configuration.nix
        ./hosts/seminars-03.eberly.cmu.edu/disko.nix
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
      ];
    };
  };
}
