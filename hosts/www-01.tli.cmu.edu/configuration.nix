{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader = {
    grub.enable = true;
  };

  networking.hostName = "www-01";
  networking.domain = "tli.cmu.edu";

  system.stateVersion = "26.05";
}
