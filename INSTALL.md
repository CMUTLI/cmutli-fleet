# Install a host

1. Boot official NixOS installer media.
2. Set a temporary installer password and start SSH.

   ```console
   passwd
   systemctl start sshd
   ip -br addr
   ```

   From the control machine:

   ```console
   ssh nixos@<installer-ip>
   ```
3. Verify the target disks. Disko overwrites every configured disk.

   ```console
   lsblk -o NAME,SIZE,MODEL,SERIAL
   ls -l /dev/disk/by-id
   ```

   Use matching `wwn-` or `scsi-` paths in `disko.nix`, never `/dev/sdX`.
4. Capture hardware modules for `hardware-configuration.nix`.

   ```console
   nixos-generate-config --show-hardware-config
   ```

   Keep filesystem and bootloader configuration in `disko.nix`. Include the
   storage-controller module required to mount root.
5. From a machine with this repository and Nix:

   ```console
   nix run github:nix-community/nixos-anywhere -- \
     --flake ".#<host-fqdn>" nixos@<installer-ip>
   ```

`nixos-anywhere` partitions the configured disks, installs the selected host,
and reboots it.
