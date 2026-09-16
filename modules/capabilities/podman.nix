{ inputs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
  };

  # All rootless containers run as deploy. Quadlet units belong in
  # /home/deploy/.config/containers/systemd, and persistent app data below
  # /srv should be owned by deploy.
  users.users.deploy.linger = true;
  users.users.deploy.autoSubUidGidRange = true;

  # Quadlet units are declarative files in deploy's user systemd manager.
  # The NixOS module installs Podman's user generator; Home Manager owns the
  # user-level Quadlet configuration when service modules add containers.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = false;
    users.deploy = { ... }: {
      home.stateVersion = "26.05";
      imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];
      virtualisation.quadlet.enable = true;
    };
  };
  #


}
