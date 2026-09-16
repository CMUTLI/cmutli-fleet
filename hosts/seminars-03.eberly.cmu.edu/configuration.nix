{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/services/eberly.cmu.edu/seminars.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # The physical hostname is distinct from the service it runs (see
  # modules/services/eberly.cmu.edu/seminars.nix for the service
  # definition itself).
  # Also distinct from other machines named seminars-03 under a different
  # domain, which this directory's FQDN-based name avoids colliding with.
  networking.hostName = "seminars-03";
  networking.domain = "eberly.cmu.edu";

  system.stateVersion = "26.05";
}
