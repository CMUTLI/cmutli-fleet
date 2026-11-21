{ inputs, lib, pkgs, ... }:

let
  # Each template line's docs site, served under its own number, as on
  # webkilt.andrew.cmu.edu: line 0 is the current CMU template. Each site is
  # built by the theme's release workflow with --baseurl
  # /jekyll-and-plaid/<line> and pinned by a flake input. Add a line's input
  # here when it ships.
  lines = {
    "0" = inputs.jekyll-and-plaid-site;
  };
  # The line that the folder's root redirects to.
  rootLine = "0";
  jp = "/jekyll-and-plaid";
  site = pkgs.runCommand "jekyll-and-plaid-docs" { } (
    "mkdir -p $out\n"
    + lib.concatStrings (lib.mapAttrsToList (line: src: "cp -r ${src} $out/${line}\n") lines)
  );
in
{
  imports = [
    ../modules/capabilities/nginx.nix
    ./themes.andrew.cmu.edu.nix
  ];

  # The theme's docs site (cmu-web/cmu-web-jekyll-and-plaid), built by its
  # release workflow with the github-pages gem, at /jekyll-and-plaid/ on the
  # themes host. Pages don't carry over between lines, so only the folder's
  # root redirects; any other path outside a line is a 404. The redirect is
  # temporary, so browsers and search engines follow rootLine when it changes.
  services.nginx.virtualHosts."themes.andrew.cmu.edu".locations = {
    "= ${jp}".return = "301 ${jp}/";
    "= ${jp}/".return = "307 ${jp}/${rootLine}/";
    "${jp}/".alias = "${site}/";
  };
}
