{ ... }:

{
  imports = [
    ./users/tli-admins.nix
    ./users/tli-interns.nix
  ];

  # Password hashes are disabled. Access is by SSH key or, where enabled,
  # Andrew Kerberos through SSH keyboard-interactive authentication.
  users.mutableUsers = false;

  users.users.deploy = {
    isNormalUser = true;
    uid = 1000;
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [ ];
  };

}
