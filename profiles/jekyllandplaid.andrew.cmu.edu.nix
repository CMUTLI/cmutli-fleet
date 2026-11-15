{ inputs, lib, pkgs, ... }:

let
  # Each template line's docs site, served under its own number, as on
  # webkilt.andrew.cmu.edu: line 0 is the current CMU template. Each site is
  # built by the theme's release workflow with --baseurl /<line> and pinned by
  # a flake input. Add a line's input here when it ships.
  lines = {
    "0" = inputs.jekyll-and-plaid-site;
  };
  # The line that the site's root redirects to.
  rootLine = "0";
  site = pkgs.runCommand "jekyllandplaid-andrew-cmu-edu" { } (
    "mkdir -p $out\n"
    + lib.concatStrings (lib.mapAttrsToList (line: src: "cp -r ${src} $out/${line}\n") lines)
  );
in
{
  imports = [
    ../modules/capabilities/nginx.nix
  ];

  security.acme.certs."jekyllandplaid.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

  # The theme's docs site (cmu-web/cmu-web-jekyll-and-plaid), built by its
  # release workflow with the github-pages gem. A new name with no old
  # http:// links to keep, so HTTP redirects to HTTPS. forceSSL would answer
  # with a 301; this sends a 308, like the other sites, and leaves the ACME
  # challenge location on port 80 alone.
  services.nginx.virtualHosts."jekyllandplaid.andrew.cmu.edu" = {
    addSSL = true;
    enableACME = true;
    root = site;
    # Pages don't carry over between lines, so only the root redirects; any
    # other path outside a line is a 404. The redirect is temporary, so
    # browsers and search engines follow rootLine when it changes.
    locations."= /".extraConfig = ''
      if ($scheme = http) {
        return 308 https://$host$request_uri;
      }
      return 307 /${rootLine}/;
    '';
    locations."/".extraConfig = ''
      if ($scheme = http) {
        return 308 https://$host$request_uri;
      }
    '';
  };
}
