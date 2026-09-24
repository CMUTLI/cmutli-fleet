# Host-specific users

Put users and groups that do not belong on every host in this directory.
Import the class from each applicable host configuration.

```nix
imports = [ ../../modules/users/tli-admins.nix ];
```

Keep fleet-wide accounts in `modules/users.nix`.
