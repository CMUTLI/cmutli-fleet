{ ... }:

{
  imports = [
    ./users/tli-admins.nix
    ./users/tli-interns.nix
  ];

  # Password hashes are disabled. Access is by SSH key or, where enabled,
  # Andrew Kerberos through SSH keyboard-interactive authentication.
  users.mutableUsers = false;

  # deploy has its own primary group so service data below /srv can be
  # restricted to it rather than shared with every normal user.
  users.groups.deploy.gid = 1000;
  users.users.deploy = {
    isNormalUser = true;
    uid = 1000;
    group = "deploy";
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [ ];
  };

}
