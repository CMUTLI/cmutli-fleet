{ lib, ... }:

let
  # The docs site (cmu-web/cmu-web-forbes-and-moreword), pinned by digest: one
  # image holds WordPress, the theme and the site built from the repository's
  # site/ into SQLite. Null leaves the container and the site out.
  # 0.1.2
  image = "ghcr.io/cmu-web/cmu-web-forbes-and-moreword@sha256:8885d8bc563f038a94d8adfe015dcc0947144137509d40d757b565633eba376d";

  httpsOnly = ''
    if ($scheme = http) {
      return 308 https://$host$request_uri;
    }
  '';
  # Nobody edits this site through the web; the container returns 404 for
  # these too. The REST API's ?rest_route= form is closed with /wp-json/.
  noRest = ''
    if ($arg_rest_route != "") {
      return 404;
    }
  '';
in
{
  imports = [
    ../modules/capabilities/nginx.nix
    ../modules/capabilities/podman.nix
  ];

  config = lib.mkIf (image != null) {
    home-manager.users.deploy.virtualisation.quadlet.containers.forbesandmoreword = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";
      };
      containerConfig = {
        inherit image;
        # Ports 3000 to 3003 on the host are placemellon's, the web kilt MCP
        # server's, qrnegie's and fencepost's.
        publishPorts = [ "127.0.0.1:3004:8080" ];
        # WordPress and PHP kept apart from the host: nothing in the image can
        # change, the database is a copy in memory, and Apache runs as
        # www-data with no capabilities. A restart puts the site back as built.
        readOnly = true;
        tmpfses = [ "/tmp:rw,size=64m,mode=1777" ];
        dropCapabilities = [ "ALL" ];
        noNewPrivileges = true;
        memory = "512m";
        pidsLimit = 256;
        # Podman ignores the image's HEALTHCHECK in OCI-format images.
        healthCmd = "curl -fsS -o /dev/null http://127.0.0.1:8080/";
        healthInterval = "30s";
        healthTimeout = "5s";
        healthStartPeriod = "20s";
      };
    };

    security.acme.certs."forbesandmoreword.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

    # A new name with no old http:// links to keep, so HTTP redirects to HTTPS
    # with a 308. The redirect sits in each proxied location, leaving the ACME
    # challenge location on port 80 alone.
    services.nginx.virtualHosts."forbesandmoreword.andrew.cmu.edu" = {
      addSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3004";
        extraConfig = httpsOnly + noRest;
      };
      locations."~ ^/(wp-admin|wp-json)(/|$)".return = "404";
      locations."~ ^/(wp-login|xmlrpc|wp-cron|wp-signup|wp-activate|wp-trackback|wp-links-opml|wp-mail|wp-comments-post)\\.php$".return = "404";
    };
  };
}
