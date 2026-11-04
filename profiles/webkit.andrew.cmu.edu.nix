{ inputs, ... }:

{
  imports = [
    ../modules/capabilities/nginx.nix
  ];

  security.acme.certs."webkit.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

  services.nginx.virtualHosts."webkit.andrew.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    root = inputs.cmu-web-kit;
  };
}
