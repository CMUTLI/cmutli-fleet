{ inputs, pkgs, ... }:

let
  kit = inputs.cmu-web-kit;
  # The kit's docs at the site's root, with its own css/ and js/ beside the
  # docs' own, as the kit's GitHub Pages workflow lays them out
  site = pkgs.runCommand "webkit-andrew-cmu-edu" { } ''
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

  security.acme.certs."webkit.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

  services.nginx.virtualHosts."webkit.andrew.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    root = site;
  };
}
