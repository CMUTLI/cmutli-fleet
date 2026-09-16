{ ... }:

{

  imports = [
    ../../capabilities/podman.nix
    ../../capabilities/nginx.nix
  ];

  systemd.tmpfiles.rules = [
    "d /srv/programs 0750 deploy deploy -"
    "d /srv/programs/mysql 0700 deploy deploy -"
  ];

  services.nginx.virtualHosts."programs.eberly.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3000";
      proxyWebsockets = true;
    };
  };
}
