{ ... }:

{
  disko.devices.disk = {
    main = {
      device = "/dev/disk/by-id/wwn-0x6000c29e240b49b0276ec19188c43980";
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
            content = {
              type = "swap";
            };
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

    data = {
      device = "/dev/disk/by-id/wwn-0x6000c29de9872bfed87a37a33c052e7f";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          srv = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/var/lib/syllabus-registry";
            };
          };
        };
      };
    };
  };
}
