{ lib, ... }:

let
  # The app (cmu-web/cmu-web-qrnegie), pinned by digest. Null leaves the
  # container and the site out.
  # 0.1.0
  image = "ghcr.io/cmu-web/cmu-web-qrnegie@sha256:09434f4667bef751ac05866824e6ef0dc47ed9b19c78571aef2d49bcdf5284e2";

  httpsOnly = ''
    if ($scheme = http) {
      return 308 https://$host$request_uri;
    }
  '';
in
{
  imports = [
    ../modules/capabilities/nginx.nix
    ../modules/capabilities/podman.nix
  ];

  config = lib.mkIf (image != null) {
    home-manager.users.deploy.virtualisation.quadlet.containers.qrnegie = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";
      };
      containerConfig = {
        inherit image;
        # Ports 3000 and 3001 on the host are placemellon's and the web
        # kilt MCP server's.
        publishPorts = [ "127.0.0.1:3002:3000" ];
        # Podman ignores the image's HEALTHCHECK in OCI-format images.
        healthCmd = "node -e \"fetch('http://localhost:3000/healthz').then(r=>process.exit(r.ok?0:1),()=>process.exit(1))\"";
        healthInterval = "30s";
        healthTimeout = "5s";
        healthStartPeriod = "60s";
      };
    };

    security.acme.certs."qrnegie.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

    # Each image is drawn on request, so image requests are limited per
    # client address. The builder redraws at most twice a second and a docs
    # page shows three codes; the burst covers both without delay.
    services.nginx.appendHttpConfig = ''
      limit_req_zone $binary_remote_addr zone=qrnegie_images:10m rate=5r/s;
    '';

    # A new name with no old http:// links to keep, so HTTP redirects to HTTPS.
    # forceSSL would answer with a 301, which lets clients turn a POST to /mcp
    # into a GET; a 308 keeps it. The redirect sits in each proxied location,
    # leaving the ACME challenge location on port 80 alone.
    services.nginx.virtualHosts."qrnegie.andrew.cmu.edu" = {
      addSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3002";
        extraConfig = httpsOnly;
      };
      locations."~ ^/qr\\.(svg|png)$" = {
        proxyPass = "http://127.0.0.1:3002";
        extraConfig = httpsOnly + ''
          limit_req zone=qrnegie_images burst=20 nodelay;
          limit_req_status 429;
        '';
      };
    };
  };
}
