{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/placemellon.andrew.cmu.edu.nix
    ../../profiles/qrnegie.andrew.cmu.edu.nix
    ../../profiles/webkilt.andrew.cmu.edu.nix
  ];

  boot.loader = {
    grub.enable = true;
  };

  networking.hostName = "www-01";
  networking.domain = "tli.cmu.edu";

  system.stateVersion = "26.05";
}
