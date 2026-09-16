{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/syllabus-registry.tli.cmu.edu.nix
  ];


  boot.loader.grub.enable = true;

  networking.hostName = "syllabus-registry-01";
  networking.domain = "tli.cmu.edu";

  system.stateVersion = "26.05";
}
