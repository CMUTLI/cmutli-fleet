{ inputs, pkgs, ... }:

let
  kit = inputs.cmu-web-kilt;
  # The kit's docs at the site's root, with its own css/ and js/ beside the
  # docs' own, as the kit's GitHub Pages workflow lays them out
  site = pkgs.runCommand "webkilt-andrew-cmu-edu" { } ''
    cp -r ${kit}/docs $out
    chmod -R u+w $out
    cp ${kit}/css/*.css $out/css/
    cp ${kit}/js/*.js $out/js/
  '';
in
{
  imports = [
    ../modules/capabilities/nginx.nix
  ];

  security.acme.certs."webkilt.andrew.cmu.edu".email = "certificates@tli.cmu.edu";
  security.acme.certs."webkit.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

  # Serves the site over HTTP as well as HTTPS, without a redirect, for old
  # clients that cannot use current TLS.
  services.nginx.virtualHosts."webkilt.andrew.cmu.edu" = {
    addSSL = true;
    enableACME = true;
    root = site;
  };

  # The site's original name, kept for old links: a permanent redirect that
  # keeps the scheme and path. Its own certificate, so neither name depends on
  # the other.
  services.nginx.virtualHosts."webkit.andrew.cmu.edu" = {
    addSSL = true;
    enableACME = true;
    locations."/".return = "301 $scheme://webkilt.andrew.cmu.edu$request_uri";
  };
}
