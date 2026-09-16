{ ... }:

{
  # Import this on every host that runs seminars. Keep service configuration
  # here so additional hosts can reuse it unchanged.
  imports = [
    ../../capabilities/podman.nix
    ../../capabilities/nginx.nix
  ];

  systemd.tmpfiles.rules = [
    "d /srv/seminars 0750 deploy deploy -"
  ];

  services.nginx.virtualHosts."seminars.eberly.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    # TODO: fill in the real upstream port once seminars' quadlet units
    # exist.
    locations."/" = {
      proxyPass = "http://127.0.0.1:3001";
      proxyWebsockets = true;
    };
  };
}
