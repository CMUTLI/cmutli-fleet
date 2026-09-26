{ lib, pkgs, ... }:

{
  # Holds the operator age identity and signing keys, passphrase protected at
  # rest and decrypted only in memory while in use. Nothing else runs here.
  services.openssh.settings = {
    KbdInteractiveAuthentication = lib.mkForce false;
    AllowUsers = [ "meribyte" ];
  };

  environment.systemPackages = with pkgs; [
    openssl
    step-cli
  ];
}
