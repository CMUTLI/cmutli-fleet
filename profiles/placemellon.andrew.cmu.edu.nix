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
      # 2.3.6
      image = "ghcr.io/cmu-web/cmu-web-placemellon@sha256:8d16f7469d6d99989bc3530c81024e74688aceceeb90b0dc1701c50ebb5b6053";
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
