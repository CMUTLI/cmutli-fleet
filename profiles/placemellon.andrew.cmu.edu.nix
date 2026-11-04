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
      image = "ghcr.io/cmu-web/cmu-web-placemellon@sha256:c33270a97ba69a5e1f1f1b10bd9894de94af9b704d2b2f9b6401cf1341d8fc6f";
      publishPorts = [ "127.0.0.1:3000:3000" ];
      # Podman ignores the image's HEALTHCHECK in OCI-format images.
      healthCmd = "node -e \"fetch('http://localhost:3000/healthz').then(r=>process.exit(r.ok?0:1),()=>process.exit(1))\"";
      healthInterval = "30s";
      healthTimeout = "5s";
      healthStartPeriod = "60s";
    };
  };

  security.acme.certs."placemellon.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

  services.nginx.virtualHosts."placemellon.andrew.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://127.0.0.1:3000";
  };
}
