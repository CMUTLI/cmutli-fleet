{ config, pkgs, inputs, ... }:

{
  imports = [
    ./capabilities/crowdstrike.nix
    ./capabilities/krb5.nix
    ./capabilities/secrets.nix
    ./users/base.nix
  ];

  # Administration tools available on every fleet host.
  environment.systemPackages = with pkgs; [
    age
    cowsay
    curl
    emacs-nox
    git
    htop
    lshw
    rsync
    sops
    tree
    vim
  ];

  networking.firewall.enable = true;

  # Disable default DHCP; the explicit systemd-networkd DHCP rules below remain active.
  networking.useDHCP = false;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.optimise.automatic = true;

  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  services.journald.extraConfig = ''
    SystemMaxUse=256M
    SystemKeepFree=1G
  '';

  sops.secrets.root-password-hash = {
    sopsFile = inputs."cmutli-fleet-secrets" + "/fleet.yaml";
    neededForUsers = true;
  };

  systemd.coredump.settings.Coredump.Storage = "none";

  # Match predictable and legacy Ethernet interface names so DHCP does not
  # depend on the interface name assigned by the system.
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

  time.timeZone = "America/New_York";

  users.users.root.hashedPasswordFile =
    config.sops.secrets.root-password-hash.path;

  zramSwap.enable = true;
}
