{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/programs.eberly.cmu.edu.nix
  ];


  boot.loader.grub.enable = true;

  networking.hostName = "programs-01";
  networking.domain = "eberly.cmu.edu";

  system.stateVersion = "26.05";
}
