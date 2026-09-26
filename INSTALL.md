# Install a host

Installing a host erases every disk named in its `disko.nix` and replaces it
with the fleet configuration. A new host first boots with root locked and
without the Falcon sensor; both arrive with its second deploy, after its SOPS
identity is added to `cmutli-fleet-secrets`.

## Background

Fleet VMs use at least 2 vCPU, 4 GB RAM, and a 40 GB OS disk, because each
host builds its own system. Service data belongs on a separate disk mounted at
`/srv`. The VMs boot with BIOS firmware, so `disko.nix` starts the OS disk with
a 1 MB `EF02` partition for GRUB; copy an existing host's layout.

Hosts are keyed by FQDN, such as `ops-01.tli.cmu.edu`, and are separate from
the service names they serve, such as `ops.tli.cmu.edu`.

## Prepare the VM

### In vSphere

Name the VM after the host FQDN, size it to at least the fleet baseline, and
boot it from official NixOS installer media.

### On the installer console

The installer already runs SSH; it only needs a password for the `nixos` user.
Set one and note the address, then do everything else over SSH. During a
reimage, DNS may still point at the old system, so use the address rather than
the host name until the install is complete.

```console
passwd
ip -br addr
```

## Add the host

### From the control machine

Capture the kernel modules and the stable disk identifiers.

```console
ssh nixos@<installer-address>
nixos-generate-config --show-hardware-config
lsblk -o NAME,SIZE,MODEL,SERIAL
ls -l /dev/disk/by-id
```

### In `cmutli-fleet`

Create `hosts/<host-fqdn>/` with three files:

- `hardware-configuration.nix`: the `boot.initrd.availableKernelModules` list
  from `nixos-generate-config`, including the storage controller driver such as
  `vmw_pvscsi`. Leave filesystems and the boot loader to `disko.nix`.
- `disko.nix`: the disk layout. Match each disk by its `wwn-` or `scsi-` path,
  never `/dev/sdX`.
- `configuration.nix`: the host's service profile and names.

<samp>hosts/&lt;host-fqdn&gt;/configuration.nix:</samp>

```nix
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/<service-fqdn>.nix
  ];

  boot.loader.grub.enable = true;

  networking.hostName = "<host>";
  networking.domain = "<domain>";

  system.stateVersion = "26.05";
}
```

Add the host to `flake.nix`, then check and commit it.

<samp>flake.nix:</samp>

```nix
nixosConfigurations."<host-fqdn>" = mkHost
  ./hosts/<host-fqdn>/configuration.nix
  ./hosts/<host-fqdn>/disko.nix;
```

```console
git add flake.nix hosts/<host-fqdn>
nix --extra-experimental-features "nix-command flakes" flake check --all-systems
git commit -m "feat: add <host-fqdn>"
git push
```

## Install

### From the control machine

`nixos-anywhere` partitions the configured disks, installs the host, and
reboots it.

```console
nix --extra-experimental-features "nix-command flakes" run \
  github:nix-community/nixos-anywhere -- \
  --flake ".#<host-fqdn>" nixos@<installer-address>
```

## After the first boot

### On the host

Generate the host's SOPS identity as described under "Fleet root password" in
the `cmutli-fleet-secrets` README, and record its recipient.

### In `cmutli-fleet-secrets`

Add the recipient to the `fleet.yaml` rule and to the host's Falcon tenant
rule, then recreate both files as that README describes.

### In `cmutli-fleet`

Refresh the pinned secrets input and deploy the host a second time, as
described under "Apply configuration" in the README.

### Verify

Root should have its password verifier, and the Falcon sensor should report
the `bpf` backend without Reduced Functionality Mode.

```console
ssh -t <admin>@<host-fqdn> 'sudo grep "^root:" /etc/shadow | cut -c1-12; sudo /opt/CrowdStrike/falconctl -g --rfm-state --backend'
```

Expect `root:$y$j9T$` and `backend=bpf, rfm-state=false`.
