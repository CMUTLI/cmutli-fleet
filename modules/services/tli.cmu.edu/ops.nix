{ config, inputs, pkgs, ... }:

let
  adminPassword = "/srv/ops/grafana/admin-password";
  grafanaFiles = inputs.cmutli-dashboards + "/grafana";
  createAdminPassword = pkgs.writeShellScript "grafana-create-admin-password" ''
    set -eu
    if [ ! -s ${adminPassword} ]; then
      umask 077
      ${pkgs.openssl}/bin/openssl rand -hex 32 > ${adminPassword}
    fi
  '';
in
{
  imports = [
    ../../capabilities/podman.nix
    ../../capabilities/nginx.nix
  ];

  systemd.tmpfiles.rules = [
    "d /srv/ops 0750 deploy deploy -"
    "d /srv/ops/grafana 0700 deploy deploy -"
    "d /srv/ops/grafana/data 0700 deploy deploy -"
  ];

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    extraFlags = [ "--storage.tsdb.retention.size=4GB" ];
    exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
    };
    scrapeConfigs = [{
      job_name = "node";
      static_configs = [{
        targets = [ "127.0.0.1:9100" ];
        labels.instance = config.networking.fqdn;
      }];
    }];
  };

  home-manager.users.deploy.virtualisation.quadlet.containers.grafana = {
    autoStart = true;
    serviceConfig = {
      ExecStartPre = createAdminPassword;
      Restart = "always";
      RestartSec = "10s";
    };
    containerConfig = {
      image = "docker.io/grafana/grafana:13.0.9";
      networks = [ "host" ];
      userns = "keep-id";
      user = "1000:1000";
      volumes = [
        "/srv/ops/grafana/data:/var/lib/grafana"
        "${adminPassword}:/run/secrets/grafana-admin-password:ro"
        "${grafanaFiles}/provisioning:/etc/grafana/provisioning:ro"
        "${grafanaFiles}/dashboards:/etc/grafana/dashboards:ro"
      ];
      environments = {
        GF_AUTH_ANONYMOUS_ENABLED = "false";
        GF_SECURITY_ADMIN_USER = "admin";
        GF_SECURITY_ADMIN_PASSWORD__FILE = "/run/secrets/grafana-admin-password";
        GF_SECURITY_COOKIE_SECURE = "true";
        GF_SERVER_HTTP_ADDR = "127.0.0.1";
        GF_SERVER_ROOT_URL = "https://ops.tli.cmu.edu/";
        GF_USERS_ALLOW_SIGN_UP = "false";
        PROMETHEUS_URL = "http://127.0.0.1:9090";
      };
    };
  };

  security.acme.certs."ops.tli.cmu.edu".email = "certificates@tli.cmu.edu";
  services.nginx.virtualHosts."ops.tli.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3000";
      proxyWebsockets = true;
    };
  };
}
