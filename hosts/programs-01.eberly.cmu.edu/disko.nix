{ ... }:

{
  disko.devices.disk.main = {
    device = "/dev/disk/by-id/wwn-0x6000c29538242cc8cd1d90d7672d4269";
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
