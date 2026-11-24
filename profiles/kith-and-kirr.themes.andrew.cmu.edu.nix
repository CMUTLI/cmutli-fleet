{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # Kith & Kirr (cmu-web/cmu-web-kith-and-kirr), a Grouper theme, at a
  # release: the repository at the tag, whose grouper/ the demo wears and
  # whose demo/ and dev/ hold the demo's settings, structure and loader, and
  # the release's built docs site (site.tar.gz, built for /kith-and-kirr/0),
  # like jekyll-and-plaid-site. Both are flake inputs; without them this file
  # adds nothing.
  kk = inputs.kith-and-kirr or null;
  kkSite = inputs.kith-and-kirr-site or null;

  # Grouper's UI (Internet2's container, the version the theme is tested
  # with), Postgres for its database and nginx in front, each pinned by
  # digest.
  # 7.9.1
  grouperImage = "docker.io/i2incommon/grouper@sha256:ee45511e9b219d754f93e2c31847f40d222aa726fe28c558349fc0c456f52795";
  # 17-alpine
  postgresImage = "docker.io/library/postgres@sha256:f9cf3e1f0066f0eb0c48707d864f0ac5941e9ff454a072077d97a4d278d07d73";
  # 1.27-alpine
  nginxImage = "docker.io/library/nginx@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef4b76fb8e2f2a10";

  # The theme's docs live under the Web Kilt line it's built on, as the other
  # themes' do, and the demo under the line, since it shows that line's
  # theme. The folder's root redirects to rootLine.
  folder = "/kith-and-kirr";
  line = "${folder}/0";
  demo = "${line}/demo";
  rootLine = "0";
  # Ports 3000 to 3005 on the host are placemellon's, the web kilt MCP
  # server's, qrnegie's, fencepost's, forbes & moreword's and scaife & sound's
  # demo's.
  port = "3006";

  # The containers' names, which they also go by on their network
  db = "kith-and-kirr-db";
  grouper = "kith-and-kirr-grouper";
  web = "kith-and-kirr-web";
  # The database lives only on the demo's internal network, which nothing
  # outside it can reach, so its password guards nothing
  dbPassword = "kith-and-kirr-demo";

  # Grouper's settings, built from the release: the theme's lines, the
  # demo's tagline and sign-in by the X-Remote-User header nginx sets, and
  # grouper.properties twice, from demo/groups.yaml's settings (the loader
  # writes them, as in development): once writable, for loading, and once with
  # demo/grouper.properties added, which makes Grouper read-only.
  conf =
    pkgs.runCommand "kith-and-kirr-demo-conf"
      {
        nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.pyyaml ])) ];
      }
      ''
        mkdir $out
        {
          cat ${kk}/grouper/properties/grouper-ui.properties
          echo
          echo "# The demo: whoever nginx names in X-Remote-User is signed in"
          echo "grouper.ui.authentication.http.header = X-Remote-User"
        } > $out/grouper-ui.properties
        cat ${kk}/grouper/properties/grouper.text.en.us.properties \
          ${kk}/demo/grouper.text.en.us.properties > $out/grouper.text.en.us.properties
        cp ${kk}/grouper/properties/Owasp.CsrfGuard.overlay.properties $out/csrfguard.properties
        cp ${kk}/dev/conf/subject.properties $out/subject.properties
        cp ${kk}/dev/conf/grouper.properties $out/grouper.properties.load
        chmod u+w $out/grouper.properties.load
        python3 ${kk}/dev/load.py --settings-only --yaml ${kk}/demo/groups.yaml \
          --properties $out/grouper.properties.load
        cat $out/grouper.properties.load ${kk}/demo/grouper.properties > $out/grouper.properties.demo
      '';

  # Grouper's start: its settings files copied into place (the CSRFGuard line
  # added to the file Grouper ships), grouper.properties writable only while
  # the nightly rebuild has left its load flag, then the image's own start
  classes = "/opt/grouper/grouperWebapp/WEB-INF/classes";
  start = pkgs.writeText "kith-and-kirr-grouper-start.sh" ''
    set -e
    mode=demo
    if [ -e /kith-and-kirr/state/load ]; then mode=load; fi
    cp /kith-and-kirr/conf/grouper.properties.$mode ${classes}/grouper.properties
    cp /kith-and-kirr/conf/grouper-ui.properties ${classes}/grouper-ui.properties
    cp /kith-and-kirr/conf/grouper.text.en.us.properties ${classes}/grouperText/grouper.text.en.us.properties
    cp /kith-and-kirr/conf/subject.properties ${classes}/subject.properties
    cat /kith-and-kirr/conf/csrfguard.properties >> ${classes}/Owasp.CsrfGuard.overlay.properties
    exec /usr/local/bin/entrypoint.sh ui
  '';

  # The demo's own web server: every visitor is Andrew Carnegie (ac00), a
  # made-up person in demo/groups.yaml's viewer group, who can see every
  # folder, group and member and change nothing; proxy_set_header replaces
  # any X-Remote-User a browser sends. Grouper runs at /grouper/, since its UI
  # reads only the first folder of an address as its own, so this server maps
  # the demo's address onto it, with Grouper's redirects and cookie path.
  # Grouper's pages use relative addresses, so nothing else needs rewriting.
  nginxConf = pkgs.writeText "kith-and-kirr-demo-nginx.conf" ''
    server {
      listen 80;
      location ${demo}/ {
        proxy_pass http://${grouper}:8080/grouper/;
        proxy_set_header Host $http_host;
        proxy_set_header X-Remote-User ac00;
        proxy_redirect ~^(?:https?://[^/]+)?/grouper/(.*)$ ${demo}/$1;
        proxy_cookie_path /grouper ${demo};
      }
      location / {
        return 404;
      }
    }
  '';

  state = "/home/deploy/.local/state/kith-and-kirr-demo";

  # Every night, the demo starts over from an empty database: Grouper's own
  # jobs can't, once it's read-only. Grouper starts writable, the loader
  # builds demo/groups.yaml and checks it, and Grouper restarts read-only.
  # nginx is down meanwhile, so nobody sees it half built.
  rebuild = pkgs.writeShellScript "kith-and-kirr-demo-rebuild" ''
    set -eu
    export PATH=/run/current-system/sw/bin:${
      lib.makeBinPath [ (pkgs.python3.withPackages (ps: [ ps.pyyaml ])) ]
    }:$PATH
    cleanup() {
      rm -f ${state}/load
      systemctl --user restart ${grouper}.service
      systemctl --user start ${web}.service
    }
    trap cleanup EXIT
    systemctl --user stop ${web}.service ${grouper}.service ${db}.service
    podman volume rm --force ${db}
    touch ${state}/load
    systemctl --user start ${db}.service ${grouper}.service
    up=
    for _ in $(seq 1 120); do
      code=$(podman exec ${grouper} curl -s -o /dev/null -w '%{http_code}' \
        "http://127.0.0.1:8080/grouper/grouperUi/app/UiV2Main.index?operation=UiV2Main.indexMain" || true)
      case "$code" in 200 | 302) up=1; break ;; esac
      sleep 5
    done
    if [ -z "$up" ]; then
      echo "Grouper didn't answer within 10 minutes" >&2
      exit 1
    fi
    python3 ${kk}/dev/load.py --engine podman --container ${grouper} --db-container ${db} \
      --yaml ${kk}/demo/groups.yaml --properties ${conf}/grouper.properties.load \
      --gsh ${state}/load.gsh
  '';
in
{
  imports = [
    ../modules/capabilities/nginx.nix
    ../modules/capabilities/podman.nix
  ];

  config = lib.mkIf (kk != null && kkSite != null) {
    home-manager.users.deploy =
      { config, ... }:
      let
        inherit (config.virtualisation.quadlet) containers networks;
      in
      {
        # The rebuild's load flag and logs, which Grouper reads
        home.file.".local/state/kith-and-kirr-demo/.keep".text = "";

        virtualisation.quadlet = {
          # Postgres and Grouper only on the internal network, with no way
          # out; nginx on it too, and on the edge network for its port
          networks.kith-and-kirr-internal.networkConfig = {
            name = "kith-and-kirr-internal";
            internal = true;
          };
          networks.kith-and-kirr-edge.networkConfig.name = "kith-and-kirr-edge";

          containers.${db} = {
            autoStart = true;
            serviceConfig = {
              Restart = "always";
              RestartSec = "10s";
            };
            containerConfig = {
              image = postgresImage;
              name = db;
              networks = [ networks.kith-and-kirr-internal.ref ];
              volumes = [
                "${db}:/var/lib/postgresql/data"
                # The people Grouper's people source reads
                "${kk}/dev/db:/docker-entrypoint-initdb.d:ro"
              ];
              environments = {
                POSTGRES_DB = "grouper";
                POSTGRES_USER = "grouper";
                POSTGRES_PASSWORD = dbPassword;
              };
              memory = "256m";
              pidsLimit = 128;
              healthCmd = "pg_isready -U grouper";
              healthInterval = "10s";
            };
          };

          containers.${grouper} = {
            autoStart = true;
            unitConfig = {
              Requires = [ containers.${db}.ref ];
              After = [ containers.${db}.ref ];
            };
            serviceConfig = {
              Restart = "always";
              RestartSec = "10s";
              # The first start makes Grouper's tables
              TimeoutStartSec = "15min";
            };
            containerConfig = {
              image = grouperImage;
              name = grouper;
              networks = [ networks.kith-and-kirr-internal.ref ];
              entrypoint = [
                "/bin/sh"
                "/kith-and-kirr/start.sh"
              ];
              volumes = [
                "${start}:/kith-and-kirr/start.sh:ro"
                "${conf}:/kith-and-kirr/conf:ro"
                "${state}:/kith-and-kirr/state:ro"
                # The theme, as a Grouper admin installs it
                "${kk}/grouper/assets/kith-and-kirr:/opt/grouper/grouperWebapp/grouperExternal/public/assets/kith-and-kirr:ro"
                "${kk}/grouper/customHeader.jsp:/opt/grouper/grouperWebapp/WEB-INF/grouperUi2/assetsJsp/customHeader.jsp:ro"
              ];
              environments = {
                GROUPER_DATABASE_URL = "jdbc:postgresql://${db}:5432/grouper";
                GROUPER_DATABASE_USERNAME = "grouper";
                GROUPER_DATABASE_PASSWORD = dbPassword;
                GROUPER_AUTO_DDL_UPTOVERSION = "v7.*.*";
                GROUPER_USE_SSL = "false";
                GROUPER_TOMCAT_HTTP_PORT = "8080";
                GROUPER_SETUP_AUTHN_VALVE = "false";
                GROUPER_RUN_TOMCAT_NOT_SUPERVISOR = "true";
                GROUPER_REDIRECT_FROM_SLASH_TO_GROUPER = "false";
                GROUPER_MAX_MEMORY = "768m";
                GROUPER_CHOWN_DIRS = "false";
                # Composite groups get their members from the daemon; a new
                # database starts without the membership cache the check
                # would wait for
                GROUPER_DAEMON = "true";
                GROUPER_WEBCLIENT_IS_SSL = "false";
                GROUPER_CHECK_MEMBERSHIP_CACHE_IS_POPULATED = "false";
              };
              noNewPrivileges = true;
              memory = "1g";
              pidsLimit = 512;
            };
          };

          containers.${web} = {
            autoStart = true;
            unitConfig = {
              Requires = [ containers.${grouper}.ref ];
              After = [ containers.${grouper}.ref ];
            };
            serviceConfig = {
              Restart = "always";
              RestartSec = "10s";
            };
            containerConfig = {
              image = nginxImage;
              name = web;
              networks = [
                networks.kith-and-kirr-internal.ref
                networks.kith-and-kirr-edge.ref
              ];
              publishPorts = [ "127.0.0.1:${port}:80" ];
              volumes = [ "${nginxConf}:/etc/nginx/conf.d/default.conf:ro" ];
              readOnly = true;
              tmpfses = [
                "/var/cache/nginx:rw,size=16m"
                "/var/run:rw,size=1m"
                "/tmp:rw,size=8m"
              ];
              memory = "64m";
              pidsLimit = 64;
            };
          };
        };

        systemd.user.services.kith-and-kirr-demo-rebuild = {
          Unit.Description = "Rebuild the Kith & Kirr demo from an empty database";
          Service = {
            Type = "oneshot";
            ExecStart = "${rebuild}";
            TimeoutStartSec = "30min";
          };
        };
        systemd.user.timers.kith-and-kirr-demo-rebuild = {
          Unit.Description = "Rebuild the Kith & Kirr demo nightly";
          Timer = {
            OnCalendar = "*-*-* 03:00:00";
            Persistent = true;
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };

    # The docs site, static, and the demo, at /kith-and-kirr/ on the themes
    # host. Pages don't carry over between lines, so only the folder's root
    # redirects, temporarily, to rootLine; any other path outside a line is a
    # 404. The demo isn't for search engines.
    services.nginx.virtualHosts."themes.andrew.cmu.edu".locations = {
      "= ${folder}".return = "301 ${folder}/";
      "= ${folder}/".return = "307 ${folder}/${rootLine}/";
      "${folder}/".return = "404";
      "${line}/".alias = "${kkSite}/";
      "${demo}/" = {
        proxyPass = "http://127.0.0.1:${port}";
        extraConfig = ''
          add_header X-Robots-Tag "noindex, nofollow" always;
        '';
      };
    };
  };
}
