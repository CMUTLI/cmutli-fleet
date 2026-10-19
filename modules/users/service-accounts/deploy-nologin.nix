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

  services.openssh.settings.DenyUsers = [ "deploy" ];
}
