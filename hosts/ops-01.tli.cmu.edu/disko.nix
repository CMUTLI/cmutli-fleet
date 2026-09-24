{ ... }:

{
  disko.devices.disk.main = {
    device = "/dev/disk/by-id/wwn-0x6000c293a2cc39b504b2516470bbcf18";
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
