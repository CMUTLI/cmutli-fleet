{ ... }:

{
  disko.devices.disk.main = {
    device = "/dev/disk/by-id/wwn-0x6000c29c04c41e7ce4c5cfc12170ef93";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          size = "1M";
          type = "EF02";
        };
        swap = {
          size = "2G";
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

  disko.devices.disk.data = {
    device = "/dev/disk/by-id/wwn-0x6000c2916dd7685f041492b3aebe0f29";
    type = "disk";
    content = {
      type = "gpt";
      partitions.data = {
        size = "100%";
        content = {
          type = "lvm_pv";
          vg = "data";
        };
      };
    };
  };

  disko.devices.lvm_vg.data = {
    type = "lvm_vg";
    lvs.srv = {
      size = "10G";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/srv";
      };
    };
  };
}
