# CMU TLI NixOS Fleet

This repository holds the NixOS configuration for the CMU TLI fleet: host
definitions, service modules, and Nix derivations. The private
`cmutli-fleet-secrets` repository contains encrypted credentials and
configuration secrets; `cmutli-fleet-vendor` contains proprietary upstream
packages; `cmutli-dashboards` contains the dashboards served by
`ops.tli.cmu.edu`.

## Background

| Path | Purpose |
| --- | --- |
| `profiles/<service-fqdn>.nix` | Shared configuration for a service pool. |
| `modules/services/<domain>/<service>.nix` | Service runtime wiring. |
| `modules/capabilities/<capability>.nix` | Reusable host capabilities. |
| `hosts/<host-fqdn>/` | Hostname, hardware, bootloader, and Disko layout. |
| `docs/services/<service-fqdn>.md` | Production service contract. |

Hosts import service profiles. Profiles import the shared baseline and service
modules. Host names and service names are separate; all paths use FQDNs where
uniqueness matters.

`modules/users.nix` defines fleet-wide accounts. Host-specific account classes
belong in `modules/users/` and are imported by the applicable hosts. Human
administrators use SSH keys or Andrew Kerberos. `deploy` runs rootless Podman
services and is SSH-denied; administrators enter it with `sudo -iu deploy`.

The private repositories are flake inputs fetched over SSH, so evaluating the
fleet requires read access to both. Neither repository's contents appear in
this one.

Application repositories document application behavior, development, and
release construction. This repository documents production operation under
[`docs/services/`](docs/services/).

## Setup

The development shell provides Git, age, and SOPS.

```console
nix develop
```

## Install a host

See [INSTALL.md](INSTALL.md). Capture hardware modules and stable disk IDs from
installer media before the first install.

## Apply configuration

Stage Nix changes before evaluating a Git flake, then check every host.

```console
git add <changed-files>
nix --extra-experimental-features "nix-command flakes" flake check --all-systems
```

### On the host

```console
sudo nixos-rebuild --extra-experimental-features "nix-command flakes" test --flake ".#<host-fqdn>"
sudo nixos-rebuild switch --flake ".#<host-fqdn>"
```

### From another machine

Evaluate locally, then build and activate on the target.

```console
nix run github:NixOS/nixpkgs/nixos-26.05#nixos-rebuild -- switch \
  --flake ".#<host-fqdn>" \
  --build-host <admin>@<host-fqdn> \
  --target-host <admin>@<host-fqdn> --sudo --ask-sudo-password --use-substitutes
```
