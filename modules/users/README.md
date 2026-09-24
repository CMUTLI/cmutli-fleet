# User classes

Put reusable user and group classes in this directory. Import fleet-wide
classes from `modules/users.nix`; import host-specific classes from the
applicable host configuration.

```nix
imports = [ ../../modules/users/tli-admins.nix ];
```
