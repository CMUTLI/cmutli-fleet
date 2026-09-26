{ ... }:

{
  users.users.meribyte = {
    isNormalUser = true;
    uid = 1001;
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+3OlnHJ5PmM0GTvvuzmk+rKQNmjtV0D9bGVFjPXdSe meribyte@hackwrench tli"
    ];
  };

  users.users.martinv = {
    isNormalUser = true;
    uid = 1002;
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
  };
}
