{ pkgs, ... }:

{
  imports = [
    ./users.nix
    ./capabilities/krb5.nix
  ];

  # Administration tools available on every fleet host.
  environment.systemPackages = with pkgs; [
    cowsay
    emacs-nox
    git
    rsync
    tree
    htop
    lshw
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
