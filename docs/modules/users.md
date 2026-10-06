# User access

This guide describes the accounts and privileges available on fleet hosts,
including the defaults and the access classes used to extend them.

## Background

User classes are NixOS modules that define accounts or grant group
memberships. A service profile is imported by every host in that service
pool, so add a class to the profile when access should be consistent across
the pool. Import a class from a host configuration only for an intentional
single-host exception.

Service processes, their data, and maintenance sessions need an account
distinct from the human administrators. The fleet provides `deploy` as a
general-purpose service account on every host for host-local work, including
rootless containers, persistent service data, and interactive sessions. Its
dedicated primary group lets service data under `/var/lib/<service>` be owned
by `deploy` rather than the shared `users` group. Its password is locked and
SSH access is denied; administrators switch to it locally with
`sudo -iu deploy`.

## Baseline behavior

Every host imports `modules/base.nix`, which imports
`modules/users/base.nix`. The user baseline imports the fleet administrator
class and disables mutable users.
`users.mutableUsers = false` keeps account state managed by NixOS.
Administrators have `wheel` access and sign in with SSH keys or Andrew
Kerberos. The fleet-wide SSH key policy accepts only inline Ed25519 keys,
including hardware-backed keys, and rejects `authorizedKeys.keyFiles`. Root's
password verifier comes from encrypted `fleet.yaml`, and root SSH login is
disabled.

## Available user modules

The fleet defines login classes, sudo classes, and a service account module:

| Account or population | No direct login | Login-only class | Login and sudo class |
| --- | --- | --- | --- |
| General-purpose<br>service account | <code>service-accounts/</code><br><code>deploy-nologin.nix</code> | N/A | N/A |
| TLI administrators | N/A | N/A | <code>classes/</code><br><code>tli-admins-sudo.nix</code> |
| TLI interns | N/A | <code>classes/</code><br><code>tli-interns.nix</code> | <code>classes/</code><br><code>tli-interns-sudo.nix</code> |

> [!NOTE]
> A sudo class imports its corresponding login class; e.g.,
> `classes/tli-interns-sudo.nix` imports `classes/tli-interns.nix`.

## Apply a user class

Import the class in each service profile whose hosts should receive these
accounts. Add the class path shown in the table to the profile's existing
`imports` list.

<samp>profiles/&lt;service-fqdn&gt;.nix:</samp>

```nix
../modules/users/<class-module>
```

Replace `<service-fqdn>` with the service profile's FQDN. Replace
`<class-module>` with the path from the table.

For access on one host only, replace `<host-fqdn>` with that host's FQDN and
add the class path to its `imports` list instead.

<samp>hosts/&lt;host-fqdn&gt;/configuration.nix:</samp>

```nix
../../modules/users/<class-module>
```

### Example: Add TLI interns to `ohq-test.tli.cmu.edu`

To grant TLI interns login access without sudo, add the following to the
profile's `imports` list.

<samp>profiles/ohq-test.tli.cmu.edu.nix:</samp>

```nix
imports = [
  ../modules/users/classes/tli-interns.nix
];
```

To grant TLI interns login and sudo access, add the sudo class to the
profile's `imports` list instead.

<samp>profiles/ohq-test.tli.cmu.edu.nix:</samp>

```nix
imports = [
  ../modules/users/classes/tli-interns-sudo.nix
];
```

## Restrict SSH login

By default, human accounts can SSH with an authorized key or authenticate
with Andrew Kerberos through keyboard-interactive PAM. Their local password
hashes are locked (`hashedPassword = "!"`), and OpenSSH password
authentication is disabled. Set `AllowUsers` in a service profile to restrict
SSH access across that service's host pool, or in a host configuration for a
single-host exception. Other provisioned accounts remain on the system but
cannot log in over SSH unless listed; local console access is unaffected.

<samp>profiles/&lt;service-fqdn&gt;.nix:</samp>

```nix
services.openssh.settings.AllowUsers = [
  "<username1>"
  "<username2>"
];
```

Replace `<service-fqdn>` with the service profile's FQDN and each `<username>`
placeholder with an account allowed to SSH to the service's hosts.

## Disable keyboard-interactive SSH authentication

Set `KbdInteractiveAuthentication` to disable keyboard-interactive
authentication on every host using the profile. This also disables SSH
authentication with Andrew credentials; public-key authentication remains
available. Use `lib.mkForce` to override the fleet baseline setting.

<samp>profiles/&lt;service-fqdn&gt;.nix:</samp>

```nix
services.openssh.settings.KbdInteractiveAuthentication = lib.mkForce false;
```

## Create a user class

A user class groups accounts under a shared access policy. Import it in a
service profile or host configuration where those accounts need access.

### Define the login class

Create `modules/users/classes/<user-class>.nix`. Give each account a stable UID
used consistently across fleet hosts. Add SSH public keys to accounts that
allow key-based SSH authentication.

<samp>modules/users/classes/&lt;user-class&gt;.nix:</samp>

```nix
{ ... }:

{
  users.users."<username>" = {
    isNormalUser = true;
    uid = <uid>;
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "<ssh-public-key>"
    ];
  };
}
```

Replace `<username>`, `<uid>`, and `<ssh-public-key>` with the account name, an
unused stable UID, and its public key. Omit `openssh.authorizedKeys.keys` when
key-based SSH login won't be used.

### Add the sudo companion class

Create `modules/users/classes/<user-class>-sudo.nix` as a companion to the
login class when those users need sudo. It imports the login class and adds
each account to `wheel`.

<samp>modules/users/classes/&lt;user-class&gt;-sudo.nix:</samp>

```nix
{ ... }:

{
  imports = [ ./<user-class>.nix ];

  users.users."<username>".extraGroups = [ "wheel" ];
}
```

Replace `<user-class>` with the login class basename and `<username>` with the
account name. Import either the login class or its sudo companion in each
configuration that should receive the accounts.

Add the classes and their access levels to the table in
[Available user modules](#available-user-modules).

## Remove a user class

In `cmutli-fleet`, remove the class import from each service profile or host
configuration where the accounts should no longer have access. Delete the
class files only after no configuration imports them. To revoke sudo while
retaining login, replace the sudo companion import with the login class
instead. Apply the updated configuration to every affected host.

Because `users.mutableUsers = false`, accounts no longer declared in the
configuration are removed from the system account databases on activation.
Their home directories and files are not deleted; review, preserve, or remove
that data separately.

Remove the class from the [Available user modules](#available-user-modules)
table.

### Audit home directories

In `cmutli-fleet`, run this from the repository root to find top-level home
directories on fleet hosts whose owner UID has no matching account:

```bash
while IFS= read -r host; do
  printf '\n== %s ==\n' "$host"
  ssh -n "$host" \
    'find /home -mindepth 1 -maxdepth 1 -type d -nouser -printf "%U %p\n"'
done < <(find hosts -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
```
