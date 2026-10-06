{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/keys.tli.cmu.edu.nix
  ];

  boot.loader = {
    grub.enable = true;
  };

  networking.hostName = "keys-01";
  networking.domain = "tli.cmu.edu";

  cmutli.crowdstrike-falcon = {
    enable = true;
    tenant = "tli-servers";
  };

  system.stateVersion = "26.05";
}
