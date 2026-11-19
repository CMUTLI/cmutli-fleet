{ lib, ... }:

let
  # Forbes & Moreword's docs site (cmu-web/cmu-web-forbes-and-moreword),
  # pinned by digest: one image holds WordPress, the theme and the site built
  # from the repository's site/ into SQLite, with
  # https://themes.andrew.cmu.edu/forbes-and-moreword as its address. Null
  # leaves the container and the site out.
  # 0.1.3
  image = "ghcr.io/cmu-web/cmu-web-forbes-and-moreword@sha256:e2e06b5b6ef23ca0e981ca7f0ae8929f59dc8e314a6f5aebe847ef63e8fe6490";

  # Nobody edits this site through the web; the container returns 404 for
  # these too. The REST API's ?rest_route= form is closed with /wp-json/.
  noRest = ''
    if ($arg_rest_route != "") {
      return 404;
    }
  '';
  fam = "/forbes-and-moreword";
in
{
  imports = [
    ../modules/capabilities/nginx.nix
    ../modules/capabilities/podman.nix
  ];

  config = lib.mkMerge [
    {
      security.acme.certs."themes.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

      # The CMU Web themes' docs, each under its own folder. The root goes to
      # the CMU Web home page until the themes have a page of their own.
      services.nginx.virtualHosts."themes.andrew.cmu.edu" = {
        forceSSL = true;
        enableACME = true;
        locations."= /".return = "302 https://cmu-web.github.io/";
        locations."/".return = "404";
      };
    }

    (lib.mkIf (image != null) {
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

      # Forbes & Moreword at /forbes-and-moreword/. WordPress gets its pages
      # with the folder still on (it takes its own address off), but Apache
      # in the image keeps files at the root, so files go without it.
      services.nginx.virtualHosts."themes.andrew.cmu.edu".locations = {
        "= ${fam}".return = "301 ${fam}/";
        "${fam}/" = {
          proxyPass = "http://127.0.0.1:3004";
          extraConfig = noRest;
        };
        "~ ^${fam}/(wp-content|wp-includes|images)/" = {
          proxyPass = "http://127.0.0.1:3004";
          extraConfig = ''
            rewrite ^${fam}(/.*)$ $1 break;
          '';
        };
        "~ ^${fam}/(wp-admin|wp-json)(/|$)".return = "404";
        "~ ^${fam}/(wp-login|xmlrpc|wp-cron|wp-signup|wp-activate|wp-trackback|wp-links-opml|wp-mail|wp-comments-post)\\.php$".return =
          "404";
      };

      # The old address, for now: everything goes to the same page here.
      security.acme.certs."forbesandmoreword.andrew.cmu.edu".email = "certificates@tli.cmu.edu";
      services.nginx.virtualHosts."forbesandmoreword.andrew.cmu.edu" = {
        forceSSL = true;
        enableACME = true;
        locations."/".return = "301 https://themes.andrew.cmu.edu${fam}$request_uri";
      };
    })
  ];
}
