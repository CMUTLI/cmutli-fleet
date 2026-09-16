{ ... }:

{
  # The existing host has a 40 GiB BIOS disk at /dev/sda. The fresh install
  # uses GPT with a BIOS boot partition; Disko will overwrite the device.
  # Replace this name with a stable /dev/disk/by-id path before provisioning.
  disko.devices.disk.main = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          size = "1M";
          type = "EF02";
        };
        swap = {
          size = "1G";
          content.type = "swap";
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
