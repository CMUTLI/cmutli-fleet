{ ... }:

{
  imports = [ ./tli-interns.nix ];

  users.users.tshea.extraGroups = [ "wheel" ];
}
