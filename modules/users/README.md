# Host-specific user classes

Put users and groups that belong to only part of the fleet in this directory.
Import the class module from each applicable host's `configuration.nix`; do
not import it from `base.nix`.

For example, a future `tli-admins.nix` would be imported with:

```nix
imports = [ ../../modules/users/tli-admins.nix ];
```

The class module owns its SSH keys, group membership, and any fixed UIDs it
needs. Keep fleet-wide accounts in `modules/users.nix` instead.
