{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/services/tli.cmu.edu/syllabus-registry.nix
  ];

  # Legacy BIOS, not UEFI: this VM's disk uses an MBR (dos) partition
  # table with a boot flag on partition 1, which Debian's installer only
  # produces when it detects BIOS firmware at install time.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  # The physical hostname is distinct from the service it runs (see
  # modules/services/tli.cmu.edu/syllabus-registry.nix for the service definition
  # itself). Also distinct from other machines named syllabus-registry-01
  # under a different domain, which this directory's FQDN-based name
  # avoids colliding with.
  networking.hostName = "syllabus-registry-01";
  networking.domain = "tli.cmu.edu";

  system.stateVersion = "26.05";
}
