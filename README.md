# CMU TLI NixOS Fleet

NixOS configuration for CMU TLI servers.

## Layout

| Path | Purpose |
| --- | --- |
| `profiles/<service-fqdn>.nix` | Shared configuration for a service pool. |
| `modules/services/<domain>/<service>.nix` | Service runtime wiring. |
| `hosts/<host-fqdn>/` | Hostname, hardware, bootloader, and Disko layout. |
| `docs/services/<service-fqdn>.md` | Production service contract. |

Hosts import service profiles. Profiles import the shared baseline and service
modules. Host names and service names are separate; all paths use FQDNs where
uniqueness matters.

`modules/users.nix` defines fleet-wide accounts. Host-specific account classes
belong in `modules/users/` and are imported by the applicable hosts.

## Access

Human administrators use SSH keys or Andrew Kerberos. `deploy` runs rootless
Podman services and is SSH-denied; administrators enter it with `sudo -iu deploy`.

## Install

See [INSTALL.md](INSTALL.md). Capture hardware modules and stable disk IDs from
installer media before the first install.

## Apply configuration

Stage Nix changes before evaluating a Git flake.

```console
git add flake.nix flake.lock modules/ profiles/ hosts/
nix --extra-experimental-features "nix-command flakes" flake check --all-systems
sudo nixos-rebuild --extra-experimental-features "nix-command flakes" test --flake ".#<host-fqdn>"
sudo nixos-rebuild switch --flake ".#<host-fqdn>"
```

For a remote host, build on the target until its Nix daemon trusts the deploy
controller:

```console
nixos-rebuild switch --flake ".#<host-fqdn>" \
  --build-host <admin>@<host-fqdn> \
  --target-host <admin>@<host-fqdn> --sudo --ask-sudo-password --use-substitutes
```

## Secrets

The public repository contains no encrypted secret files. Encrypted host files,
recipient policy, and key bootstrap procedures are in private
`CMUTLI/cmutli-fleet-secrets`.

## Service documentation

Application repositories document application behavior, development, and
release construction. This repository documents production operation under
[`docs/services/`](docs/services/).
