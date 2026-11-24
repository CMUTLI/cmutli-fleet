{ lib, pkgs, ... }:

let
  # The app (CMUEberlyCenter/cmueberlycenter-programs), pinned by digest. Null
  # leaves the app's container and its nightly chores out.
  # 0.1.1
  image = "ghcr.io/cmueberlycenter/cmueberlycenter-programs@sha256:a324e9e5cf1314548bbfb7af9ac8246f51591459a84aea575b4442a0550c39f9";

  # The demo runs Rails in development: the developer sign-in and made-up
  # data only. False runs it in production.
  demo = true;

  # The Rails secret, written once on the host by the activation script below.
  appEnv = "/var/lib/programs/app.env";
in
{
  imports = [
    ../modules/capabilities/podman.nix
    ../modules/capabilities/nginx.nix
  ];

  # storage/ holds the app's SQLite databases and uploaded files.
  systemd.tmpfiles.rules = [
    "d /var/lib/programs 0750 deploy deploy -"
    "d /var/lib/programs/storage 0700 deploy deploy -"
  ];

  system.activationScripts.programs-env = {
    deps = [ "users" ];
    text = ''
      install -d -m 0750 -o deploy -g deploy /var/lib/programs
      if [ ! -e ${appEnv} ]; then
        umask 077
        printf 'SECRET_KEY_BASE=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 64)" > ${appEnv}
        chown deploy:deploy ${appEnv}
      fi
    '';
  };

  home-manager.users.deploy = lib.mkIf (image != null) {
    virtualisation.quadlet.containers.programs = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";
      };
      containerConfig = {
        name = "programs";
        inherit image;
        publishPorts = [ "127.0.0.1:3000:3000" ];
        environmentFiles = [ appEnv ];
        environments = {
          RAILS_ENV = if demo then "development" else "production";
          APP_HOST = "programs.eberly.cmu.edu";
        };
        # :U gives the folder to the container's user.
        volumes = [ "/var/lib/programs/storage:/app/storage:U" ];
        # Podman ignores the image's HEALTHCHECK in OCI-format images.
        healthCmd = "curl -fsS http://localhost:3000/up";
        healthInterval = "30s";
        healthTimeout = "5s";
        healthStartPeriod = "60s";
      };
    };

    # Progress recalculation and the other nightly chores.
    systemd.user.services.programs-nightly = {
      Unit.Description = "Eberly Programs nightly chores";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.podman}/bin/podman exec programs bin/rails cron:nightly_chores";
      };
    };
    systemd.user.timers.programs-nightly = {
      Unit.Description = "Eberly Programs nightly chores";
      Timer = {
        OnCalendar = "*-*-* 03:30:00";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };

  security.acme.certs."programs.eberly.cmu.edu".email = "certificates@eberly.cmu.edu";

  services.nginx.virtualHosts."programs.eberly.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3000";
      proxyWebsockets = true;
      # The demo's made-up data stays out of search engines.
      extraConfig = lib.optionalString demo ''
        add_header X-Robots-Tag "noindex, nofollow" always;
      '';
    };
  };
}
