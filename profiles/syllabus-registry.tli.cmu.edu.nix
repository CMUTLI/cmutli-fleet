{ config, pkgs, ... }:

let
  maintenancePage = pkgs.writeTextDir "not-available.html"
    (builtins.readFile ./syllabus-registry.tli.cmu.edu/not-available.html);
in
{
  imports = [
    ../modules/capabilities/nginx.nix
    ../modules/capabilities/podman.nix
  ];

  # The application runs from its Compose file as deploy until Quadlet units
  # replace it.
  environment.systemPackages = [ pkgs.podman-compose ];

  systemd.tmpfiles.rules = [
    "d /var/lib/syllabus-registry 0750 deploy deploy -"
  ];

  # Application environment, read by the Compose services as their env_file,
  # and the S3 Course API credentials the sync service adds to it.
  sops.secrets.app-env = {
    owner = "deploy";
    group = "deploy";
    mode = "0400";
  };
  sops.secrets.s3-env = {
    owner = "deploy";
    group = "deploy";
    mode = "0400";
  };

  security.acme.certs."syllabus-registry.tli.cmu.edu".email = "certificates@tli.cmu.edu";

  # When the application is not answering, visitors get the maintenance page.
  services.nginx.virtualHosts."syllabus-registry.tli.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    root = maintenancePage;
    extraConfig = ''
      error_page 502 503 504 /not-available.html;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:3001";
      proxyWebsockets = true;
    };
    locations."= /not-available.html".extraConfig = ''
      internal;
    '';
  };
}
