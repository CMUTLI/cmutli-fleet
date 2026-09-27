{ lib, pkgs, ... }:

{
  services.openssh.settings = {
    KbdInteractiveAuthentication = lib.mkForce false;
    AllowUsers = [ "meribyte" ];
  };

  environment.systemPackages = with pkgs; [
    openssl
    step-cli
  ];
}
