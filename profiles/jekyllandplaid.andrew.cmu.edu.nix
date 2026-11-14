{ inputs, ... }:

{
  imports = [
    ../modules/capabilities/nginx.nix
  ];

  security.acme.certs."jekyllandplaid.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

  # The theme's docs site (cmu-web/cmu-web-jekyll-and-plaid), built by its
  # release workflow with the github-pages gem and pinned by the
  # jekyll-and-plaid-site flake input. A new name with no old http:// links to
  # keep, so HTTP redirects to HTTPS.
  services.nginx.virtualHosts."jekyllandplaid.andrew.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    root = inputs.jekyll-and-plaid-site;
  };
}
