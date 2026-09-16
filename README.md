# cmutli-fleet

Declarative NixOS configuration for the CMU TLI server fleet. Replaces
`tli-saltstack-base`.

## Structure

Three tiers, each answering a different question:

- **Service profile** (`profiles/<service-fqdn>.nix`): the complete shared
  desired state for a service pool. For example,
  `programs.eberly.cmu.edu.nix` imports the baseline plus Programs'
  Podman/nginx wiring. A `programs-02.eberly.cmu.edu` host imports that same
  profile and therefore receives the identical service configuration.
  FQDN names avoid ambiguity: `www.eberly.cmu.edu` and `www.tli.cmu.edu` are
  different profiles. The corresponding production contract lives at
  `docs/services/<service-fqdn>.md`.
- **Service module** (`modules/services/<domain>/<service>.nix`): reusable
  application wiring imported by its FQDN profile. It pulls in only the
  capabilities it needs (`modules/capabilities/`: Podman, nginx, Kerberos).
- **Host** (`hosts/<fqdn>/`): inventory for one physical machine. It imports
  a service profile and holds only node-specific configuration: hostname,
  bootloader, disks, and hardware. Directories use full FQDNs because short
  hostnames are not unique across domains. Each holds a
  `configuration.nix`, a `disko.nix` (disk partitioning, see
  "Provisioning a new VM" below), and a `hardware-configuration.nix` for
  whatever else the real machine needs (CPU vendor, microcode, extra
  kernel modules). Capture storage-controller modules from installer media
  before the first install so the target initrd can mount its root disk.

`base.nix` supplies the shared headless-server baseline through every service
profile. A genuinely different machine role can get a profile once more than
one host needs it. Secret-backed capabilities are imported only by profiles
that need them, so a new host can boot before its SOPS file exists.

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
3. Before installing, run `nixos-generate-config --show-hardware-config` on
   the booted installer and copy its hardware-specific kernel modules into
   the host's `hardware-configuration.nix`. This is required after creating
   a new VM and before its first NixOS install: its initrd needs the detected
   storage-controller driver to mount root. Keep generated filesystem and
   bootloader entries in `disko.nix`. Also record `lsblk -o
   NAME,SIZE,MODEL,SERIAL` and `ls -l /dev/disk/by-id`; use the matching
   `wwn-` or `scsi-` path in `disko.nix`, never `/dev/sdX`.
4. From a machine with this repository checked out and Nix available:

   ```console
   nix run github:nix-community/nixos-anywhere -- \
     --flake ".#<fqdn>" root@<installer-ip>
   ```

   This partitions the disk per that host's `disko.nix`, installs NixOS
   per its `configuration.nix`, and reboots into the real system. Nothing
   from the installer session persists.
## Applying a host's configuration

From the repository root, stage the Nix changes before evaluating the flake.
Git-aware flake evaluation otherwise ignores untracked files and can evaluate
an older revision.

```console
git add flake.nix modules/ hosts/
nix --extra-experimental-features "nix-command flakes" flake lock
git add flake.lock
nix --extra-experimental-features "nix-command flakes" flake check --all-systems
sudo nixos-rebuild --extra-experimental-features "nix-command flakes" test --flake ".#syllabus-registry-01.tli.cmu.edu"
sudo nixos-rebuild switch --flake ".#syllabus-registry-01.tli.cmu.edu"
```

Run `switch` only after `test` succeeds.

## Secrets and deployment

Secrets (database passwords, the CrowdStrike CID, OAuth client secrets,
and similar) are managed with sops-nix and never committed in plaintext.
See `secrets/README.md` for the full workflow.

Containerized apps run under rootless Podman as `deploy`, via declarative
user-level Quadlet units (`modules/capabilities/podman.nix`). Home Manager
owns `deploy`'s Quadlet configuration and Podman's user generator turns it
into systemd user units. Deploys are deliberate: CI should build and push
images to GHCR, then a `workflow_dispatch` action should SSH in as `deploy`
to pull a specific tag or digest and restart that unit. No auto-update timer
runs on a production host.

## Service documentation

Production service contracts live under [`docs/services/`](docs/services/).
They complement, rather than duplicate, the application repositories: app
repositories document behavior and releases; this fleet documents production
operation.

## Known gaps

- `syllabus-registry-01` and `programs-01` still need their
  `docker-compose.yml`-based services translated into quadlet units under
  `/home/deploy/.config/containers/systemd`.
- `crowdstrike.nix` wires up the per-host CID secret but does not yet
  package `falcon-sensor` itself; see the TODO in that file.
- Both hosts use a fresh GPT layout compatible with BIOS GRUB. The
  `syllabus-registry-01` layout retains its 40G OS / 200G `/srv` split;
  `programs-01` has one 40G OS disk with 1G swap and a verified VMware WWN.
- `hardware-configuration.nix` for Syllabus Registry is a placeholder pending
  capture from that VM's installer media.
- No `workflow_dispatch` deploy action or quadlet units exist yet; image
  pulls and service restarts remain manual until those are added.
- Kerberos login here is PAM password auth via keyboard-interactive, not
  GSSAPI ticket forwarding. A `kinit`'d admin still gets a password
  prompt; true ticket-based SSO would need `GSSAPIAuthentication` plus a
  keytab and is not set up.
- Set `security.acme.defaults.email` to a real operational contact before
  enabling a public HTTPS virtual host.
- The install walkthrough deliberately has no screenshots yet; capture them
  during the first real boot and add them under `assets/`.
