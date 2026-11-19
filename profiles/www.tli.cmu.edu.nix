{ inputs, ... }:

let
  # TLI's website, until www.tli.cmu.edu has a site of its own. A 302, so
  # browsers don't remember it and the root stays free.
  tliWebsite = "302 https://www.cmu.edu/tli-office/";
in
{
  imports = [
    ../modules/capabilities/nginx.nix
  ];

  # One certificate for both names.
  security.acme.certs."www.tli.cmu.edu" = {
    email = "certificates@tli.cmu.edu";
    extraDomainNames = [ "tli.cmu.edu" ];
  };

  # TLI's login pages (CMUTLI/cmutli-login-pages): static pages that send
  # people on to a service's real sign-in, such as learning.cmu.edu's at
  # /login/learning/. Only the repository's login/ folder is served, so its
  # README and workflows never are. Anything else is the login
  # pages' own 404, except the root, which goes to TLI's website.
  services.nginx.virtualHosts."www.tli.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    extraConfig = ''
      error_page 404 /login/404.html;
    '';
    locations."/login/".alias = "${inputs.cmutli-login-pages}/login/";
    locations."= /login/404.html" = {
      alias = "${inputs.cmutli-login-pages}/login/404.html";
      extraConfig = "internal;";
    };
    locations."= /".return = tliWebsite;
    locations."/".return = "404";
  };

  # The bare name: its root goes to TLI's website too, and everything else
  # to the same address on www.
  services.nginx.virtualHosts."tli.cmu.edu" = {
    forceSSL = true;
    useACMEHost = "www.tli.cmu.edu";
    locations."= /".return = tliWebsite;
    locations."/".return = "301 https://www.tli.cmu.edu$request_uri";
  };
}
