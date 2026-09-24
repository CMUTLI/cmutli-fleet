# User classes

Put reusable user and group classes in this directory. Import fleet-wide
classes from `modules/users.nix`; import host-specific classes from the
applicable host configuration.

`tli-interns-sudo.nix` grants TLI interns `wheel`; import it only on hosts
where that access is required.

```nix
imports = [ ../../modules/users/tli-admins.nix ];
```
