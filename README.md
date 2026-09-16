# cmutli-fleet

Declarative NixOS configuration for the CMU TLI server fleet. Replaces
`tli-saltstack-base`.

## Structure

Two tiers, each answering a different question:

- **Service** (`modules/services/<domain>/<service>.nix`): what app does
  this machine run? `tli.cmu.edu/syllabus-registry.nix`,
  `eberly.cmu.edu/seminars.nix`. Grouped by domain because a short service
  label like `www` is not unique fleet-wide: `tli.cmu.edu/www.nix` and
  `eberly.cmu.edu/www.nix` would be two unrelated services that happen to
  share a name, not the same service twice. A service backed by several
  machines (for example `www-01` and `www-02` both serving the same `www`)
  just imports that one file on both and gets the same service definition,
  Podman/nginx wiring, and vhost on each. A host importing a service
  module pulls in whatever capabilities that service needs
  (`modules/capabilities/`: podman, nginx, Kerberos); hosts do
  not import capabilities directly.
- **Host** (`hosts/<fqdn>/`): one physical machine, importing `base.nix`
  plus whichever service(s) it runs. Directories are named by full FQDN,
  not short hostname, since short hostnames are not unique across domains
  in this fleet (a future `www-01` could exist under `core.cmu.edu`,
  `eberly.cmu.edu`, and `tli.cmu.edu` at once). Each holds a
  `configuration.nix`, a `disko.nix` (disk partitioning, see
  "Provisioning a new VM" below), and a `hardware-configuration.nix` for
  whatever else the real machine needs (CPU vendor, microcode, extra
  kernel modules); the checked-in ones are placeholders until a machine
  actually exists.

There is no separate machine-role tier yet. Shared headless-server config
lives in `base.nix`; a genuinely different machine role can get a module
once more than one host needs it. Secret-backed capabilities are imported
only by the hosts that need them, so a new host can boot before its SOPS
file exists.

`modules/users.nix` (imported by `base.nix`) defines the fleet-wide users:
`deploy` (CI/deploy automation, sudo) and named human admins (sudo). All
rootless containers also run as `deploy`; service modules do not create
separate container accounts.

## User classes

Keep fleet-wide accounts in `modules/users.nix`. Host-specific classes belong
in `modules/users/<class>.nix` and are imported directly by the host configs;
a host can import more than one class module. A class module owns its users,
groups, SSH keys, and fixed UIDs only when shared storage requires them. This
keeps an Eberly-only or TLI-only account from landing on every host and makes
the host's access policy visible in its `configuration.nix`.

Admin login has two paths: the SSH keys listed per user in `users.nix`, or
Andrew (CMU Kerberos) credentials via SSH's keyboard-interactive prompt
(`modules/capabilities/krb5.nix`). SSH is restricted to the `wheel` group.

`secrets/` holds sops-encrypted, per-host secrets. See
`secrets/README.md`.

## Hostname versus service name

A host's `networking.hostName` (for example `syllabus-registry-01`) is not
the same as the DNS name of the service it runs (for example
`syllabus-registry.tli.cmu.edu`, set as a `services.nginx.virtualHosts`
entry in that service's module). Keeping these separate means a service
can move to a new host, or a host can be repurposed to a different
service, without renaming either.

## Provisioning a new VM

No golden images: every VM starts from official NixOS installer media,
every time. For the click-by-click version with screenshots, see
`INSTALL.md`; the short version:

1. Create the VM on the hypervisor and boot it from the NixOS installer ISO.
   Confirm the host's firmware mode and disk identities against its
   `disko.nix`; Disko will overwrite the selected device.
2. On the booted installer, set a temporary root password
   (`passwd`) and note the VM's IP address. It's discarded once the real
   install boots.
3. From a machine with this repository checked out and Nix available:

   ```console
   nix run github:nix-community/nixos-anywhere -- \
     --flake ".#<fqdn>" root@<installer-ip>
   ```

   This partitions the disk per that host's `disko.nix`, installs NixOS
   per its `configuration.nix`, and reboots into the real system. Nothing
   from the installer session persists.
4. Once it is back up, log in as an admin and run
   `nixos-generate-config --show-hardware-config` to fill in that host's
   `hardware-configuration.nix` (see the Structure section above for what
   belongs there versus in `disko.nix`).

## Applying a host's configuration

From the repository root, after `flake.lock` has been generated and reviewed:

```console
nix --extra-experimental-features "nix-command flakes" flake lock
nix --extra-experimental-features "nix-command flakes" flake check --all-systems
sudo nixos-rebuild --extra-experimental-features "nix-command flakes" test --flake ".#syllabus-registry-01.tli.cmu.edu"
sudo nixos-rebuild switch --flake ".#syllabus-registry-01.tli.cmu.edu"
```

Run `switch` only after `test` succeeds.

## Secrets and deployment

Secrets (database passwords, the CrowdStrike CID, OAuth client secrets,
and similar) are managed with sops-nix and never committed in plaintext.
See `secrets/README.md` for the full workflow.

Containerized apps run under rootless Podman as `deploy`, via quadlet units
(`modules/capabilities/podman.nix`). Deploys are deliberate: CI should build
and push images to GHCR, then a `workflow_dispatch` action should SSH in as
`deploy` to pull a specific tag or digest and restart that unit. No
auto-update timer runs on a production host.

## Known gaps

- `syllabus-registry-01` and `seminars-03` still need their
  `docker-compose.yml`-based services translated into quadlet units under
  `/home/deploy/.config/containers/systemd`.
- `crowdstrike.nix` wires up the per-host CID secret but does not yet
  package `falcon-sensor` itself; see the TODO in that file.
- `syllabus-registry-01`'s current device names (`/dev/sda` and `/dev/sdb`)
  still need to be replaced with stable `/dev/disk/by-id` paths after a
  final target check. Its 40G OS / 200G data layout and BIOS/MBR boot setup
  are retained. `seminars-03` still assumes a placeholder `/dev/vda` disk
  with UEFI/systemd-boot; confirm its disk and firmware before installing.
- `hardware-configuration.nix` for both hosts is a placeholder pending
  real hardware.
- No `workflow_dispatch` deploy action or quadlet units exist yet; image
  pulls and service restarts remain manual until those are added.
- Kerberos login here is PAM password auth via keyboard-interactive, not
  GSSAPI ticket forwarding. A `kinit`'d admin still gets a password
  prompt; true ticket-based SSO would need `GSSAPIAuthentication` plus a
  keytab and is not set up.
- The ACME contact address is still a placeholder in
  `modules/capabilities/nginx.nix`; replace it before enabling a public
  HTTPS virtual host.
- The install walkthrough deliberately has no screenshots yet; capture them
  during the first real boot and add them under `assets/`.
