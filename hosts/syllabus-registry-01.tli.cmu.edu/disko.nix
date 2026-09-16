{ ... }:

{



  disko.devices.disk = {
    os = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "table";
        format = "msdos";
        partitions = [
          {
            name = "root";
            start = "1MiB";
            end = "34GiB";
            bootable = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          }
          {
            name = "swap";
            start = "34GiB";
            end = "100%";
            content = {
              type = "swap";
            };
          }
        ];
      };
    };




    data = {
      device = "/dev/sdb";
      type = "disk";
      content = {
        type = "table";
        format = "msdos";
        partitions = [
          {
            name = "srv";
            start = "1MiB";
            end = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/srv";
            };
          }
        ];
      };
    };
  };
}
