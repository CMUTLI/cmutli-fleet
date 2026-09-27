{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader = {
    grub.enable = true;
  };

  networking.hostName = "keys-01";
  networking.domain = "tli.cmu.edu";

  cmutli.crowdstrike.tenant = "tli-servers";

  system.stateVersion = "26.05";
}
