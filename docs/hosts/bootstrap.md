# Bootstrap the CMU TLI fleet

Use this guide to install the first fleet host before the keys service is
available.

> [!IMPORTANT]
> For any host after the first, follow
> [Add a host to the CMU TLI fleet](README.md).

## Background

The public `cmutli-fleet` repository defines each host's NixOS configuration.
Each host generates its own age identity for SOPS. `cmutli-fleet-secrets` holds
encrypted shared secrets, including the root password verifier.
The keys service enrolls host identities as recipients of fleet secrets. Since
it is not running yet, encrypt the initial `fleet.yaml` to the first host's
public recipient. This host will eventually run the keys service and enroll
later hosts.

## Prepare the repositories

Clone the repositories as siblings under a working directory:

```console
cd "<working-directory>"
git clone git@github.com:CMUTLI/cmutli-fleet.git
git clone git@github.com:CMUTLI/cmutli-fleet-secrets.git
```

Replace `<working-directory>` with the parent directory where you want the
checkouts.

The tree below shows the target layout for the two repositories:

```text
<working-directory>/
├── cmutli-fleet/
│   ├── flake.nix
│   ├── flake.lock
│   ├── modules/
│   │   ├── base.nix
│   │   ├── capabilities/
│   │   │   ├── krb5.nix
│   │   │   └── secrets.nix
│   │   └── users/
│   │       ├── base.nix
│   │       ├── classes/
│   │       │   └── tli-admins-sudo.nix
│   │       ├── service-accounts/
│   │       │   └── deploy-nologin.nix
│   │       └── ssh-key-policy.nix
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

Later sections add the development flakes, modules, first host configuration,
and encrypted secrets.

## Create the development flakes

The development flakes provide the tools used to configure and check each
repository. Each lock file pins the exact revisions of its flake inputs. Let
Nix create the lock files naturally as each flake is first used later in this
process.

### From your computer

In `cmutli-fleet-secrets`, create the development flake.

<samp>cmutli-fleet-secrets/flake.nix:</samp>

```nix
{
  description = "Secrets management tools for the CMU TLI server fleet";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    in {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              age
              git
              jq
              mkpasswd
              openssl
              sops
            ];
          };
        });
    };
}
```

Each Git input in `cmutli-fleet/flake.nix` must have a commit for Nix to fetch.

Commit and push the initial `cmutli-fleet-secrets` repository before evaluating
the fleet flake:

```console
cd cmutli-fleet-secrets
git add flake.nix
git commit -m "build: add development flake"
git push -u origin main
```

In `cmutli-fleet`, create the development flake.

<samp>cmutli-fleet/flake.nix:</samp>

```nix
{
  description = "NixOS configuration for the CMU TLI server fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # External NixOS modules.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fleet-owned source repositories.
    cmutli-fleet-secrets = {
      url = "git+ssh://git@github.com/CMUTLI/cmutli-fleet-secrets.git";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, sops-nix, disko, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      hostSystem = "x86_64-linux";
      mkHost = hostModule: diskModule: nixpkgs.lib.nixosSystem {
        system = hostSystem;
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/base.nix
          diskModule
          disko.nixosModules.disko
          hostModule
          sops-nix.nixosModules.sops
        ];
      };
    in {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              age
              git
              sops
            ];
          };
        });

      # #### Fleet hosts ####
      # Add new entries below in alphabetical order.
      #
      # nixosConfigurations."keys-01.tli.cmu.edu" = mkHost
      #   ./hosts/keys-01.tli.cmu.edu/configuration.nix
      #   ./hosts/keys-01.tli.cmu.edu/disko.nix;
      #
      # nixosConfigurations."ops-01.tli.cmu.edu" = mkHost
      #   ./hosts/ops-01.tli.cmu.edu/configuration.nix
      #   ./hosts/ops-01.tli.cmu.edu/disko.nix;
    };
}
```

Commit the starter flake before adding the first host:

```console
cd ../cmutli-fleet
git add flake.nix
git commit -m "build: add development flake"
```

## Create the fleet modules

In `cmutli-fleet`, create the fleet modules. Fleet modules are reusable pieces
of NixOS configuration. Grouping related settings into modules lets hosts share
common behavior while keeping capabilities and user configuration separate.

Create the module directories:

```console
mkdir -p modules/capabilities modules/users/classes modules/users/service-accounts
```

### Create the base module

The base module brings together the settings needed by every fleet host.
Capability and user configuration live in separate modules, which the base
imports.

Create the base module using the file content below.

<samp>cmutli-fleet/modules/base.nix:</samp>

```nix
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./capabilities/krb5.nix
    ./capabilities/secrets.nix
    ./users/base.nix
  ];

  environment.systemPackages = with pkgs; [
    age
    cowsay
    curl
    emacs-nox
    git
    htop
    lshw
    rsync
    sops
    tree
    vim
  ];

  networking.firewall.enable = true;

  # The explicit systemd-networkd DHCP rules below remain active.
  networking.useDHCP = false;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.optimise.automatic = true;
  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  services.journald.extraConfig = ''
    SystemMaxUse=256M
    SystemKeepFree=1G
  '';

  sops.secrets.root-password-hash = {
    sopsFile = inputs."cmutli-fleet-secrets" + "/fleet.yaml";
    neededForUsers = true;
  };

  systemd.coredump.settings.Coredump.Storage = "none";

  systemd.network = {
    enable = true;
    networks = {
      "10-ethernet-dhcp" = {
        matchConfig.Name = "en*";
        networkConfig.DHCP = "yes";
      };
      "11-legacy-ethernet-dhcp" = {
        matchConfig.Name = "eth*";
        networkConfig.DHCP = "yes";
      };
    };
  };

  time.timeZone = "America/New_York";

  users.users.root.hashedPasswordFile =
    config.sops.secrets.root-password-hash.path;

  zramSwap.enable = true;
}
```

### Create the capability modules

The base imports two capability modules by default: Kerberos support for Andrew
authentication and SOPS support to decrypt each host's secrets. After bootstrap,
add imports for other fleet-wide capabilities to the base as needed.

Create the Kerberos module using the file content below.

<samp>cmutli-fleet/modules/capabilities/krb5.nix:</samp>

```nix
{ ... }:

{
  security.krb5 = {
    enable = true;
    settings = {
      libdefaults.default_realm = "ANDREW.CMU.EDU";
      realms."ANDREW.CMU.EDU" = {
        admin_server = "kerberos.andrew.cmu.edu";
        default_domain = "andrew.cmu.edu";
      };
    };
  };

  security.pam.krb5.enable = true;
}
```

Create the SOPS module using the file content below.

<samp>cmutli-fleet/modules/capabilities/secrets.nix:</samp>

```nix
{ config, inputs, ... }:

{
  sops.age.keyFile = "/var/lib/sops-age/identity.txt";
  sops.defaultSopsFile = inputs."cmutli-fleet-secrets"
    + "/hosts/${config.networking.fqdn}.yaml";
}
```

### Create the user modules

The baseline user configuration imports one user class, TLI sytem admins, and
one general purpose service account, deploy.

> [!WARNING]
> A user class imported here can grant its users login or sudo access on every
> fleet host. A service-account module creates that account on every fleet host.
> Import either here only when that fleet-wide scope is intended.

Create the base user module using the file content below.

<samp>cmutli-fleet/modules/users/base.nix:</samp>

```nix
{ ... }:

{
  imports = [
    ./classes/tli-admins-sudo.nix
    ./service-accounts/deploy-nologin.nix
    ./ssh-key-policy.nix
  ];

  users.mutableUsers = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };
}
```

Provide administrator access using the template below. Add at least one
administrator entry, and include an entry for each account that should have sudo
access on every fleet host.

<samp>cmutli-fleet/modules/users/classes/tli-admins-sudo.nix:</samp>

```nix
{ ... }:

{
  users.users = {
    "<username1>" = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPassword = "!";
      openssh.authorizedKeys.keys = [
        "<ed25519-public-key1>"
      ];
    };

    "<username2>" = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPassword = "!";
      openssh.authorizedKeys.keys = [
        "<ed25519-public-key2>"
      ];
    };
  };
}
```

Replace `<username1>`, `<username2>`, and the corresponding public-key
placeholders with each administrator's account name and SSH public key. Omit
`openssh.authorizedKeys.keys` for administrators without SSH keys.

Provide the non-login `deploy` account using the file content below.

<samp>cmutli-fleet/modules/users/service-accounts/deploy-nologin.nix:</samp>

```nix
{ ... }:

{
  users.groups.deploy.gid = 1000;
  users.users.deploy = {
    isNormalUser = true;
    uid = 1000;
    group = "deploy";
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [ ];
  };

  services.openssh.settings.DenyUsers = [ "deploy" ];
}
```

The SSH key policy checks every user's authorized keys during Nix evaluation.
It permits inline Ed25519 keys, including security-key Ed25519, and rejects
key files or other key types so unsupported keys fail the configuration check.

Create the policy using the file content below.

<samp>cmutli-fleet/modules/users/ssh-key-policy.nix:</samp>

```nix
{ config, lib, ... }:

let
  allowed = [ "ssh-ed25519" "sk-ssh-ed25519@openssh.com" ];
  isAllowed = key: lib.any (word: lib.elem word allowed)
    (lib.splitString " " key);
  violations = lib.concatLists (lib.mapAttrsToList (name: user:
    map (key: "${name} (${lib.head (lib.splitString " " key)})")
      (lib.filter (key: !isAllowed key) user.openssh.authorizedKeys.keys)
    ++ lib.optional (user.openssh.authorizedKeys.keyFiles != [ ])
      "${name} (authorizedKeys.keyFiles)")
    config.users.users);
in
{
  assertions = [{
    assertion = violations == [ ];
    message = "Only Ed25519 SSH keys may be authorized, listed inline: "
      + lib.concatStringsSep ", " violations;
  }];
}
```

### Commit the modules

Nix only evaluates files tracked by Git. Add and commit the modules before
continuing:

```console
git add modules
git commit -m "feat: add fleet modules"
```

## Look at us, almost a fleet

At this point, the development flakes and shared modules are in place. The
lock files will be created on first use; host configuration and encrypted fleet
secrets are still ahead:

```text
✓   <working-directory>/
✓   ├── cmutli-fleet/
✓   │   ├── flake.nix
    │   ├── flake.lock
✓   │   ├── modules/
✓   │   │   ├── base.nix
✓   │   │   ├── capabilities/
✓   │   │   │   ├── krb5.nix
✓   │   │   │   └── secrets.nix
✓   │   │   └── users/
✓   │   │       ├── base.nix
✓   │   │       ├── classes/
✓   │   │       │   └── tli-admins-sudo.nix
✓   │   │       ├── service-accounts/
✓   │   │       │   └── deploy-nologin.nix
✓   │   │       └── ssh-key-policy.nix
    │   └── hosts/
    │       └── <host-fqdn>/
    │           ├── configuration.nix
    │           ├── hardware-configuration.nix
    │           └── disko.nix
✓   └── cmutli-fleet-secrets/
✓       ├── flake.nix
        ├── flake.lock
        ├── .sops.yaml
        └── fleet.yaml
```

## Choose the first host

The keys service enrolls host identities as recipients of encrypted fleet
secrets, so you bring it up first. Ideally, it runs on a single-service host,
and the hostname is chosen accordingly, e.g., `keys-01.tli.cmu.edu`. If the keys
service will run on a multi-service host, name this first host for its next most
visible service, e.g., `ops-01.tli.cmu.edu`.

> [!IMPORTANT]
> A dedicated host limits the keys service's exposure to unrelated workloads.
> If one becomes available later, migrate the keys service to it; the original
> host can keep its name and any other services.

For general host and service naming conventions, see
[Choose host and service names](README.md#choose-host-and-service-names).

## Prepare the first host

Ensure the [Prerequisites](README.md#prerequisites) from the host guide are
satisfied.

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
[Prepare the first host](#prepare-the-first-host).

<samp>cmutli-fleet-secrets/.sops.yaml:</samp>

```yaml
creation_rules:
  - path_regex: ^fleet\.yaml$
    age: <host-recipient>
```

Choose the fleet root password and store it securely. On a Linux machine with
Nix, generate its verifier with `mkpasswd`, which prompts for the password:

```console
nix --extra-experimental-features "nix-command flakes" \
  shell nixpkgs#whois -c mkpasswd -m yescrypt
```

The command prints the verifier (`$y$...`), which you will need after the next
step.

Create `fleet.yaml` with SOPS, which opens an editor:

```console
cd ../cmutli-fleet-secrets
nix --extra-experimental-features "nix-command flakes" develop -c sops fleet.yaml
```

> [!TIP]
> SOPS uses Vim by default. To choose another editor, run
> `SOPS_EDITOR="<editor>" nix --extra-experimental-features "nix-command flakes" develop -c sops fleet.yaml`
> (e.g.,
> `SOPS_EDITOR="nano" nix --extra-experimental-features "nix-command flakes" develop -c sops fleet.yaml`).

Substitute `<root-password-verifier>` with the verifier printed earlier.

<samp>cmutli-fleet-secrets/fleet.yaml, in the SOPS editor:</samp>

```yaml
root-password-hash: "<root-password-verifier>"
```

Save and close the editor to encrypt the file.

Commit the encrypted file and creation rule:

```console
git add .sops.yaml fleet.yaml flake.lock
git commit -m "feat: initialize fleet secrets"
git push
cd ../cmutli-fleet
```

## Complete the first host installation

Host enrollment and monitoring certificate setup depend on the keys service.
Follow the host guide in order, setting up the keys service after host
verification and before configuring base modules:

* [Check and publish the fleet configuration](README.md#check-and-publish-the-fleet-configuration)
* [Install NixOS](README.md#install-nixos)
* [Verify the host](README.md#verify-the-host)
* [Set up the keys service](../services/keys.tli.cmu.edu.md#set-up-the-keys-service)
* [Configure base modules](README.md#configure-base-modules)

With the keys service ready, [add subsequent hosts](README.md) to the fleet.
