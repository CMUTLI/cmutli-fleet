{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/services/eberly.cmu.edu/programs.nix
  ];


  boot.loader.grub.enable = true;

  networking.hostName = "programs-01";
  networking.domain = "eberly.cmu.edu";

  system.stateVersion = "26.05";
}
