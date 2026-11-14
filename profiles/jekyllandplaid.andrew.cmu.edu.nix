{ inputs, ... }:

{
  imports = [
    ../modules/capabilities/nginx.nix
  ];

  security.acme.certs."jekyllandplaid.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

  # The theme's docs site (cmu-web/cmu-web-jekyll-and-plaid), built by its
  # release workflow with the github-pages gem and pinned by the
  # jekyll-and-plaid-site flake input. A new name with no old http:// links to
  # keep, so HTTP redirects to HTTPS. forceSSL would answer with a 301; this
  # sends a 308, like the other sites, and leaves the ACME challenge location
  # on port 80 alone.
  services.nginx.virtualHosts."jekyllandplaid.andrew.cmu.edu" = {
    addSSL = true;
    enableACME = true;
    root = inputs.jekyll-and-plaid-site;
    locations."/".extraConfig = ''
      if ($scheme = http) {
        return 308 https://$host$request_uri;
      }
    '';
  };
}
