{ pkgs, ... }:

{
  imports = [
    ./users.nix
    ./capabilities/krb5.nix
  ];

  # Minimal tools expected on every machine in this fleet.
  environment.systemPackages = with pkgs; [
    git
    rsync
    tree
    htop
    curl
    vim
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/New_York";

  services.openssh = {
    enable = true;
    settings = {
      # SSH keys and Andrew Kerberos are the supported login paths.
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
      AllowGroups = [ "wheel" ];
    };
  };

  networking.firewall.enable = true;

}
