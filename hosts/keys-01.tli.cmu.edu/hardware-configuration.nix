{ lib, ... }:

{
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "vmw_pvscsi"
    "floppy"
    "sd_mod"
    "sr_mod"
  ];

  virtualisation.vmware.guest = {
    enable = true;
    headless = true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
