{ ... }:

{



  disko.devices.disk = {
    os = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          bios = {
            size = "1M";
            type = "EF02";
          };
          root = {
            size = "34G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
          swap = {
            size = "100%";
            content = {
              type = "swap";
            };
          };
        };
      };
    };




    data = {
      device = "/dev/sdb";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          srv = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/srv";
            };
          };
        };
      };
    };
  };
}
