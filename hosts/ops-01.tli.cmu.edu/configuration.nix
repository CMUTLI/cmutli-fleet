{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/ops.tli.cmu.edu.nix
  ];

  boot.loader.grub.enable = true;

  networking.hostName = "ops-01";
  networking.domain = "tli.cmu.edu";

  system.stateVersion = "26.05";
}
