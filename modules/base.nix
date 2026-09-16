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

  # Fleet VMs obtain their addresses through DHCP. Match predictable and legacy
  # Ethernet interface names so the configuration is independent of VMware's
  # assigned interface number.
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks = {
      "10-ethernet-dhcp" = {
        matchConfig.Name = "en*";
        networkConfig.DHCP = "yes";
      };
      "11-legacy-ethernet-dhcp" = {
        matchConfig.Name = "eth*";
        networkConfig.DHCP = "yes";
      };
    };
  };

}
