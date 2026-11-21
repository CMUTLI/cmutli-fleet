{ inputs, lib, ... }:

let
  # Hunt & Peck (cmu-web/cmu-web-hunt-and-peck) at a release: the repository
  # at the tag, whose theme/ the demo wears, and the release's built docs
  # site (site.tar.gz, built with Docs & Donner), like jekyll-and-plaid-site.
  # It has no release yet, so there are no flake inputs and this file adds
  # nothing. After its first release, add to flake.nix's inputs:
  #   hunt-and-peck = { url = "github:cmu-web/cmu-web-hunt-and-peck/0.1.0"; flake = false; };
  #   hunt-and-peck-site = {
  #     url = "https://github.com/cmu-web/cmu-web-hunt-and-peck/releases/download/0.1.0/site.tar.gz";
  #     flake = false;
  #   };
  # and this file turns on as it stands.
  hp = inputs.hunt-and-peck or null;
  hpSite = inputs.hunt-and-peck-site or null;

  # Vaultwarden (dani-garcia/vaultwarden), pinned by digest, the same version
  # as vault.tli.cmu.edu but a separate container with nothing in common.
  # 1.37.5
  image = "docker.io/vaultwarden/server@sha256:4fe17f415f90087377d37c755e0ea3cf189dcc6794e49cdd2a9adbb4937d9e1f";

  # The demo's whole vault: one made-up account, Andrew Carnegie
  # (ac00@andrew.cmu.edu, with the password Hunt & Peck's docs publish), and
  # made-up items. scripts/hunt-and-peck-demo-seed.py makes it. Each start
  # copies it into memory, so a restart puts the demo back as it was.
  seed = ./hunt-and-peck-demo/seed.sqlite3;

  # The theme's docs live under the Web Kilt line it's built on, as the other
  # themes' do, and the demo under the line, since it shows that line's
  # theme. The folder's root redirects to rootLine.
  folder = "/hunt-and-peck";
  line = "${folder}/0";
  demo = "${line}/demo";
  rootLine = "0";
  # Ports 3000 to 3004 on the host are placemellon's, the web kilt MCP
  # server's, qrnegie's, fencepost's and forbes & moreword's.
  port = "3005";

  # Every visitor shares the demo account, so the demo is read-only at the
  # edge: only GET and HEAD reach Vaultwarden, apart from the requests that
  # sign in. Nobody can change the password, turn on two-step login, delete
  # the account or store anything, even signed in.
  toDemo = {
    proxyPass = "http://127.0.0.1:${port}";
    proxyWebsockets = true;
  };
in
{
  imports = [
    ../modules/capabilities/nginx.nix
    ../modules/capabilities/podman.nix
  ];

  config = lib.mkIf (hp != null && hpSite != null) {
    home-manager.users.deploy = {
      virtualisation.quadlet.containers.hunt-and-peck-demo = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10s";
        };
        containerConfig = {
          inherit image;
          publishPorts = [ "127.0.0.1:${port}:8080" ];
          # Nothing on disk: the image can't change, the vault lives in
          # memory and starts from the seed each time
          readOnly = true;
          tmpfses = [
            "/data:rw,size=64m,mode=0700"
            "/tmp:rw,size=16m,mode=1777"
          ];
          volumes = [
            "${seed}:/seed/seed.sqlite3:ro"
            "${hp}/theme/user.vaultwarden.scss.hbs:/theme/scss/user.vaultwarden.scss.hbs:ro"
          ];
          entrypoint = [
            "/bin/sh"
            "-c"
            "cp /seed/seed.sqlite3 /data/db.sqlite3 && exec /start.sh"
          ];
          environments = {
            DOMAIN = "https://themes.andrew.cmu.edu${demo}";
            # A port above 1024, so the container needs no capabilities
            ROCKET_PORT = "8080";
            TEMPLATES_FOLDER = "/theme";
            IP_HEADER = "X-Real-IP";
            IP_HEADER_TRUSTED_PROXIES = "local";
            # No new accounts, no sharing and nothing that sends mail,
            # stores files or reaches other sites. ADMIN_TOKEN is left out,
            # which turns the admin page off.
            SIGNUPS_ALLOWED = "false";
            INVITATIONS_ALLOWED = "false";
            SENDS_ALLOWED = "false";
            EMERGENCY_ACCESS_ALLOWED = "false";
            ORG_CREATION_USERS = "none";
            USER_ATTACHMENT_LIMIT = "0";
            ORG_ATTACHMENT_LIMIT = "0";
            PASSWORD_HINTS_ALLOWED = "false";
            SHOW_PASSWORD_HINT = "false";
            DISABLE_ICON_DOWNLOAD = "true";
          };
          dropCapabilities = [ "ALL" ];
          noNewPrivileges = true;
          memory = "256m";
          pidsLimit = 128;
          healthCmd = "/healthcheck.sh";
          healthInterval = "30s";
          healthTimeout = "5s";
          healthStartPeriod = "30s";
        };
      };

      # Back to the seed every night, whatever happened during the day
      systemd.user.services.hunt-and-peck-demo-reset = {
        Unit.Description = "Put the Hunt & Peck demo back to its seed";
        Service = {
          Type = "oneshot";
          ExecStart = "/run/current-system/sw/bin/systemctl --user restart hunt-and-peck-demo.service";
        };
      };
      systemd.user.timers.hunt-and-peck-demo-reset = {
        Unit.Description = "Put the Hunt & Peck demo back to its seed nightly";
        Timer = {
          OnCalendar = "*-*-* 04:00:00";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };

    # The docs site, static, and the demo, at /hunt-and-peck/ on the themes
    # host. Pages don't carry over between lines, so only the folder's root
    # redirects, temporarily, to rootLine; any other path outside a line is a
    # 404. Vaultwarden marks every demo page noindex itself.
    services.nginx.virtualHosts."themes.andrew.cmu.edu".locations = {
      "= ${folder}".return = "301 ${folder}/";
      "= ${folder}/".return = "307 ${folder}/${rootLine}/";
      "${folder}/".return = "404";
      "${line}/".alias = "${hpSite}/";

      "${demo}/" = toDemo // {
        extraConfig = ''
          limit_except GET HEAD {
            deny all;
          }
        '';
      };
      "~ ^${demo}/(identity/connect/token|identity/accounts/prelogin(/password)?|api/accounts/prelogin|notifications/hub/negotiate)$" =
        toDemo;
      "~ ^${demo}/admin".return = "404";
      # The web vault asks for its welcome dialog's picture at the site's
      # root, not under the demo's folder
      "= /images/welcome-dialog-graphic.png".proxyPass =
        "http://127.0.0.1:${port}${demo}/images/welcome-dialog-graphic.png";

      # The theme's Open Sans, from the same site as the web vault, which its
      # Content Security Policy requires for fonts. The theme asks for
      # /cmu-web/fonts/ (its $font-path) at the site's root, so the demo needs
      # no theme setting of its own.
      "/cmu-web/fonts/".alias = "${hp}/theme/fonts/";
    };
  };
}
