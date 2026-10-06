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

  # Administrators use deploy locally with sudo -iu deploy, never SSH.
  services.openssh.settings.DenyUsers = [ "deploy" ];
}
