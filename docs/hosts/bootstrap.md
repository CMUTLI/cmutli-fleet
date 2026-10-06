# Bootstrap the CMU TLI fleet

Use this guide to install the first fleet host before the keys service is
available.

Subsequent hosts will be provisioned and installed using the
[Fleet hosts](README.md) procedure.

## Background

The public `cmutli-fleet` repository defines each host's NixOS configuration.
Each host generates its own age identity for SOPS. `cmutli-fleet-secrets` holds
the encrypted shared secrets, including the root password verifier.
The keys service normally adds new hosts as recipients of those files. With
no keys service yet, the initial files are encrypted to the first host's
public recipient before installation.

## Choose the first host

Keys is the first service to bring up. Ideally, it runs on its own host,
e.g., `keys-01.tli.cmu.edu`. If it will start on a multi-service host, name the
host after the non-keys primary service, e.g., `ops-01.tli.cmu.edu`.

For general host and service naming conventions, see
[Choose host and service names](README.md#choose-host-and-service-names).

## Prepare the repositories

The fleet and secrets repositories live in sibling checkouts. The steps below
build up this layout:

```text
<working-directory>/
├── cmutli-fleet/
│   ├── flake.nix
│   ├── flake.lock
│   ├── modules/
│   └── hosts/
│       └── <host-fqdn>/
│           ├── configuration.nix
│           ├── hardware-configuration.nix
│           └── disko.nix
└── cmutli-fleet-secrets/
    ├── flake.nix
    ├── flake.lock
    ├── .sops.yaml
    └── fleet.yaml
```

The starter fleet flake below defines the inputs, host builder, and
development shell used during installation.

<samp>cmutli-fleet/flake.nix:</samp>

```nix
{
  description = "NixOS configuration for the CMU TLI server fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cmutli-fleet-secrets = {
      url = "git+ssh://git@github.com/CMUTLI/cmutli-fleet-secrets.git";
      flake = false;
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, sops-nix, disko, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkHost = hostModule: diskModule: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/base.nix
          hostModule
          diskModule
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
        ];
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ age git sops ];
      };
    };
}
```

## Prepare the host

Complete the host guide's [prerequisites](README.md#prerequisites), except for
having a running keys service.

Follow these consecutive sections of the host guide:

* [Provision a host](README.md#provision-a-host)
* [Prepare to install](README.md#prepare-to-install)
* [Add host to the fleet repository](README.md#add-host-to-the-fleet-repository)
* [Partition the host disks](README.md#partition-the-host-disks)
* [Generate the host identity](README.md#generate-the-host-identity)

Return here with the identity's public key from the final step. The next
section refers to it as `<host-recipient>`.

## Initialize fleet secrets

Create the fleet's encrypted root-password hash and add the first host as a
recipient. On first boot, NixOS decrypts the hash during activation so root
login on the console works.

### From your computer

In `cmutli-fleet-secrets`, add a creation rule to `.sops.yaml` for `fleet.yaml`.
Replace `<host-recipient>` with the public key from
[Prepare the host](#prepare-the-host).

<samp>.sops.yaml:</samp>

```yaml
creation_rules:
  - path_regex: ^fleet\.yaml$
    age: <host-recipient>
```

Choose the fleet root password and store it securely. Generate its verifier
with `mkpasswd`, which prompts for the password:

```console
nix --extra-experimental-features "nix-command flakes" \
  shell nixpkgs#whois -c mkpasswd -m yescrypt
```

The command prints the verifier (`$y$...`), which you will need after the next
step.

Create `fleet.yaml` with SOPS, which opens an editor:

```console
nix --extra-experimental-features "nix-command flakes" develop
sops fleet.yaml
```

> [!TIP]
> SOPS uses Vim by default. To choose another editor, run
> `SOPS_EDITOR="<editor>" sops fleet.yaml` (e.g.,
> `SOPS_EDITOR="nano" sops fleet.yaml`).

Substitute `<root-password-verifier>` with the verifier printed earlier.

<samp>fleet.yaml, in the SOPS editor:</samp>

```yaml
root-password-hash: "<root-password-verifier>"
```

Save and close the editor to encrypt the file.

Commit the encrypted file and creation rule:

```console
git add .sops.yaml fleet.yaml
git commit -m "feat: initialize fleet secrets"
git push
```

## Complete the first host installation

Host enrollment and monitoring certificate setup depend on the keys service.
Follow the host guide in order, setting up the keys service after host
verification and before configuring base modules:

* [Check and publish the fleet configuration](README.md#check-and-publish-the-fleet-configuration)
* [Install NixOS](README.md#install-nixos)
* [Verify the host](README.md#verify-the-host)
* [Set up the keys service](../services/keys.tli.cmu.edu.md#set-up-the-keys-service)
* [Configure base modules](README.md#base-modules)

With the keys service ready, [add subsequent hosts](README.md) to the fleet.
