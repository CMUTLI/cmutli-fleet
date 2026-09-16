# Installation Procedures for TLI NixOS Systems

## 1. Boot standard NixOS installer media

_Screenshot to capture during the first real install walkthrough._

## 2. Drop to a shell and set a temporary root password

`nixos-anywhere` wipes and reinstalls the selected disk from scratch. Verify
the target VM and its disk layout before setting a temporary password.

```console
passwd
```

_Screenshot to capture during the first real install walkthrough._

## 3. Note the installer's IP address

```console
ip a
```

_Screenshot to capture during the first real install walkthrough._

## 4. From a machine with cmutli-fleet checked out, run nixos-anywhere

```console
nix run github:nix-community/nixos-anywhere -- --flake ".#<fqdn>" root@<installer-ip>
```

Swap `<fqdn>` for the host you're installing (for example
`syllabus-registry-01.tli.cmu.edu`) and `<installer-ip>` for the address
from step 3.

_Screenshot to capture during the first real install walkthrough._

## 5. Reboot

`nixos-anywhere` partitions the disk per that host's `disko.nix`,
installs NixOS per its `configuration.nix`, and reboots into the real
system on its own. There's no need to log back into the installer
directly; that session and its temporary root password are gone once the
real system takes over.

Note: `nixos-anywhere`'s install log only exists on the machine you ran
it from, not on the target, so if something goes wrong partway through,
that terminal is where the actual error is. Once the real system is up,
see the cmutli-fleet README for how to run `nixos-rebuild switch` from
here.
