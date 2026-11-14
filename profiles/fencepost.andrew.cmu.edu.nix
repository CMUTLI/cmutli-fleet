{ lib, ... }:

let
  # The app (cmu-web/cmu-web-fencepost), pinned by digest. Null leaves the
  # container and the site out; FencePost has no release yet.
  image = null;

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
    home-manager.users.deploy.virtualisation.quadlet.containers.fencepost = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";
      };
      containerConfig = {
        inherit image;
        # Ports 3000 to 3002 on the host are placemellon's, the web kilt MCP
        # server's and qrnegie's.
        publishPorts = [ "127.0.0.1:3003:3000" ];
        # Podman ignores the image's HEALTHCHECK in OCI-format images. This
        # assumes a Node image with /healthz, like the other CMU Web apps.
        healthCmd = "node -e \"fetch('http://localhost:3000/healthz').then(r=>process.exit(r.ok?0:1),()=>process.exit(1))\"";
        healthInterval = "30s";
        healthTimeout = "5s";
        healthStartPeriod = "60s";
      };
    };

    security.acme.certs."fencepost.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

    # Each preview loads someone's page in a browser, so requests are limited
    # per client address. Narrow this to the capture route once the app has
    # one.
    services.nginx.appendHttpConfig = ''
      limit_req_zone $binary_remote_addr zone=fencepost:10m rate=2r/s;
    '';

    # A new name with no old http:// links to keep, so HTTP redirects to HTTPS
    # with a 308, which keeps a POST a POST. The redirect sits in the proxied
    # location, leaving the ACME challenge location on port 80 alone.
    services.nginx.virtualHosts."fencepost.andrew.cmu.edu" = {
      addSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3003";
        extraConfig = httpsOnly + ''
          limit_req zone=fencepost burst=10 nodelay;
          limit_req_status 429;
        '';
      };
    };
  };
}
