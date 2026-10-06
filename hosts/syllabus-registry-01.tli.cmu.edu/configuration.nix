{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/syllabus-registry.tli.cmu.edu.nix
  ];


  boot.loader = {
    grub.enable = true;
  };

  networking.hostName = "syllabus-registry-01";
  networking.domain = "tli.cmu.edu";

  cmutli.crowdstrike = {
    enable = true;
    tenant = "tli-servers";
  };

  system.stateVersion = "26.05";
}
