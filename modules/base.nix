{ config, pkgs, inputs, ... }:

{
  imports = [
    ./users.nix
    ./ssh-key-policy.nix
    ./capabilities/krb5.nix
    ./capabilities/secrets.nix
    ./capabilities/crowdstrike.nix
  ];

  # Administration tools available on every fleet host.
  environment.systemPackages = with pkgs; [
    age
    cowsay
    emacs-nox
    git
    rsync
    sops
    tree
    htop
    lshw
    curl
    vim
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # The fleet root password verifier is decrypted at activation into a
  # root-only file. Until a host's identity is added to fleet.yaml, root stays
  # locked; administrators use their own accounts and sudo.
  sops.secrets.root-password-hash = {
    sopsFile = inputs."cmutli-fleet-secrets" + "/fleet.yaml";
    neededForUsers = true;
  };
  users.users.root.hashedPasswordFile =
    config.sops.secrets.root-password-hash.path;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  services.journald.extraConfig = ''
    SystemMaxUse=256M
    SystemKeepFree=1G
  '';
  systemd.coredump.settings.Coredump.Storage = "none";

  time.timeZone = "America/New_York";

  services.openssh = {
    enable = true;
    settings = {
      # Human administrators use SSH keys or Andrew Kerberos. The deploy
      # service identity is reached locally with sudo -iu deploy, never SSH.
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
      DenyUsers = [ "deploy" ];
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
