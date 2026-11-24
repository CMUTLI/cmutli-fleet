{ lib, ... }:

let
  # Forbes & Moreword's docs site (cmu-web/cmu-web-forbes-and-moreword),
  # pinned by digest: one image holds WordPress, the theme and the site built
  # from the repository's site/ into SQLite, with
  # https://themes.andrew.cmu.edu/forbes-and-moreword as its address. Null
  # leaves the container and the site out.
  # 0.1.8
  image = "ghcr.io/cmu-web/cmu-web-forbes-and-moreword@sha256:7b6d80ff33667554d0ad035e9d6f40e28c7e1399256b3ffef4c0a034e66fc55f";

  # Nobody edits this site through the web; the container returns 404 for
  # these too. The REST API's ?rest_route= form is closed with /wp-json/.
  noRest = ''
    if ($arg_rest_route != "") {
      return 404;
    }
  '';
  # Each theme's docs live under the Web Kilt line the theme is built on
  # (/0/ is the current CMU template), as on webkilt.andrew.cmu.edu; the
  # theme's folder redirects to rootLine. The image is line 0's site, with
  # that address built in.
  fam = "/forbes-and-moreword";
  famLine = "${fam}/0";
  rootLine = "0";
in
{
  imports = [
    ../modules/capabilities/nginx.nix
    ../modules/capabilities/podman.nix
    # Scaife & Sound's docs and demo; it adds nothing until the theme's first
    # release is a flake input
    ./scaife-and-sound.themes.andrew.cmu.edu.nix
    # Kith & Kirr's docs and its live demo, a read-only Grouper
    ./kith-and-kirr.themes.andrew.cmu.edu.nix
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

      # Forbes & Moreword's line 0 at /forbes-and-moreword/0/. WordPress gets
      # its pages with the folders still on (it takes its own address off),
      # but Apache in the image keeps files at the root, so files go without
      # them. The folder's root redirects to rootLine, temporarily, so
      # browsers and search engines follow it when it changes; any other path
      # outside a line is a 404, as for every theme.
      services.nginx.virtualHosts."themes.andrew.cmu.edu".locations = {
        "= ${fam}".return = "301 ${fam}/";
        "= ${fam}/".return = "307 ${fam}/${rootLine}/";
        "${fam}/".return = "404";
        "${famLine}/" = {
          proxyPass = "http://127.0.0.1:3004";
          extraConfig = noRest;
        };
        "~ ^${famLine}/(wp-content|wp-includes|images)/" = {
          proxyPass = "http://127.0.0.1:3004";
          extraConfig = ''
            rewrite ^${famLine}(/.*)$ $1 break;
          '';
        };
        "~ ^${fam}(/[0-9]+)?/(wp-admin|wp-json)(/|$)".return = "404";
        "~ ^${fam}(/[0-9]+)?/(wp-login|xmlrpc|wp-cron|wp-signup|wp-activate|wp-trackback|wp-links-opml|wp-mail|wp-comments-post)\\.php$".return =
          "404";
      };

      # The names people try for a CMU WordPress theme: each goes to Forbes &
      # Moreword's docs, with its own certificate.
      security.acme.certs."wordpress.andrew.cmu.edu".email = "certificates@tli.cmu.edu";
      services.nginx.virtualHosts."wordpress.andrew.cmu.edu" = {
        forceSSL = true;
        enableACME = true;
        locations."/".return = "301 https://themes.andrew.cmu.edu${fam}/";
      };
      security.acme.certs."wp.andrew.cmu.edu".email = "certificates@tli.cmu.edu";
      services.nginx.virtualHosts."wp.andrew.cmu.edu" = {
        forceSSL = true;
        enableACME = true;
        locations."/".return = "301 https://themes.andrew.cmu.edu${fam}/";
      };
    })
  ];
}
