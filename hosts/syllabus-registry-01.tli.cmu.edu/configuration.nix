{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/services/tli.cmu.edu/syllabus-registry.nix
  ];


  boot.loader.grub.enable = true;

  # The physical hostname is distinct from the service it runs (see
  # modules/services/tli.cmu.edu/syllabus-registry.nix for the service definition
  # itself). Also distinct from other machines named syllabus-registry-01
  # under a different domain, which this directory's FQDN-based name
  # avoids colliding with.
  networking.hostName = "syllabus-registry-01";
  networking.domain = "tli.cmu.edu";

  system.stateVersion = "26.05";
}
