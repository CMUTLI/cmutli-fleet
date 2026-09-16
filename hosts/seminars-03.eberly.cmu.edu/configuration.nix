{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/services/eberly.cmu.edu/seminars.nix
  ];

  # The existing system boots from an MBR disk without an EFI partition.
  boot.loader.grub = {
    enable = true;
    device = "/dev/disk/by-id/wwn-0x6000c29538242cc8cd1d90d7672d4269";
  };

  # The physical hostname is distinct from the service it runs (see
  # modules/services/eberly.cmu.edu/seminars.nix for the service
  # definition itself).
  # Also distinct from other machines named seminars-03 under a different
  # domain, which this directory's FQDN-based name avoids colliding with.
  networking.hostName = "seminars-03";
  networking.domain = "eberly.cmu.edu";

  system.stateVersion = "26.05";
}
