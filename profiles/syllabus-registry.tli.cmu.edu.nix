{ config, pkgs, ... }:

let
  maintenancePage = pkgs.writeTextDir "not-available.html"
    (builtins.readFile ./syllabus-registry.tli.cmu.edu/not-available.html);
  demoAuth = ''
    auth_basic "Syllabus Registry demo";
    auth_basic_user_file ${config.sops.secrets.demo-htpasswd.path};
  '';
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

  sops.secrets.demo-htpasswd.owner = config.services.nginx.user;

  security.acme.certs."syllabus-registry.tli.cmu.edu".email = "certificates@tli.cmu.edu";

  # Everyone gets the maintenance page with a 503. Visiting /demo sets a
  # cookie that routes requests to the application, which still requires the
  # demo password.
  services.nginx.virtualHosts."syllabus-registry.tli.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    root = maintenancePage;
    extraConfig = ''
      error_page 503 /not-available.html;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:3001";
      proxyWebsockets = true;
      extraConfig = ''
        if ($cookie_sr_demo != "1") {
          return 503;
        }
      '' + demoAuth;
    };
    locations."= /demo".extraConfig = ''
      add_header Set-Cookie "sr_demo=1; Path=/; Secure; HttpOnly; SameSite=Lax" always;
      return 302 /dev/login;
    '';
    locations."= /not-available.html".extraConfig = ''
      internal;
    '';
  };
}
