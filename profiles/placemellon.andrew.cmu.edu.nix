{ ... }:

{
  imports = [
    ../modules/capabilities/nginx.nix
    ../modules/capabilities/podman.nix
  ];

  home-manager.users.deploy.virtualisation.quadlet.containers.placemellon = {
    autoStart = true;
    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
    };
    containerConfig = {
      image = "ghcr.io/cmu-web/cmu-web-placemellon@sha256:47c4f0fa745b3b502d060a784ff6faa7038919753b7e9d2d818935281300d29f";
      publishPorts = [ "127.0.0.1:3000:3000" ];
      # Podman ignores the image's HEALTHCHECK in OCI-format images.
      healthCmd = "node -e \"fetch('http://localhost:3000/healthz').then(r=>process.exit(r.ok?0:1),()=>process.exit(1))\"";
      healthInterval = "30s";
      healthTimeout = "5s";
      healthStartPeriod = "60s";
    };
  };

  security.acme.certs."placemellon.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

  # Serves image URLs over HTTP as well as HTTPS, without a redirect, so
  # existing http:// links keep working.
  services.nginx.virtualHosts."placemellon.andrew.cmu.edu" = {
    addSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://127.0.0.1:3000";
  };
}
