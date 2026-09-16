{ ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
  };

  # All rootless containers run as deploy. Quadlet units belong in
  # /home/deploy/.config/containers/systemd, and persistent app data below
  # /srv should be owned by deploy.
  users.users.deploy.linger = true;
  #



}
