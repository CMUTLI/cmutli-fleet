{ pkgs, ... }:

let
  maintenancePage = pkgs.writeTextDir "not-available.html"
    (builtins.readFile ./syllabus-registry.tli.cmu.edu/not-available.html);
in
{
  imports = [
    ../modules/capabilities/nginx.nix
  ];

  security.acme.certs."syllabus-registry.tli.cmu.edu".email = "certificates@tli.cmu.edu";

  # The application is not running yet, so every request gets the maintenance
  # page with a 503.
  services.nginx.virtualHosts."syllabus-registry.tli.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    root = maintenancePage;
    extraConfig = ''
      error_page 503 /not-available.html;
    '';
    locations."/".return = "503";
    locations."= /not-available.html".extraConfig = ''
      internal;
    '';
  };
}
