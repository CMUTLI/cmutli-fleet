{ config, lib, ... }:

let
  # Only Ed25519 keys, including hardware-backed ones. A key line may begin
  # with options, so its type is looked for among all of its words.
  allowed = [ "ssh-ed25519" "sk-ssh-ed25519@openssh.com" ];
  isAllowed = key: lib.any (w: lib.elem w allowed) (lib.splitString " " key);

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
