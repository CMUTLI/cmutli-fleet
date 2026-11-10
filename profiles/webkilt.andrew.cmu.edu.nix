{
  inputs,
  lib,
  pkgs,
  ...
}:

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
  # The kit's MCP server (cmu-web/cmu-web-kilt-mcp), pinned by digest. Null
  # leaves the container and /mcp out.
  # 0.1.0
  mcpImage = "ghcr.io/cmu-web/cmu-web-kilt-mcp@sha256:40ec3f480186bbb88164d789a8b26f5b2678df0314682a1026f77c05141518e5";
in
{
  imports = [
    ../modules/capabilities/nginx.nix
    ../modules/capabilities/podman.nix
  ];

  home-manager.users.deploy.virtualisation.quadlet.containers.webkilt-mcp =
    lib.mkIf (mcpImage != null)
      {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10s";
        };
        containerConfig = {
          image = mcpImage;
          # Port 3000 on the host is placemellon's.
          publishPorts = [ "127.0.0.1:3001:3000" ];
          # Podman ignores the image's HEALTHCHECK in OCI-format images.
          healthCmd = "node -e \"fetch('http://localhost:3000/healthz').then(r=>process.exit(r.ok?0:1),()=>process.exit(1))\"";
          healthInterval = "30s";
          healthTimeout = "5s";
          healthStartPeriod = "60s";
        };
      };

  security.acme.certs."webkilt.andrew.cmu.edu".email = "certificates@tli.cmu.edu";
  security.acme.certs."webkit.andrew.cmu.edu".email = "certificates@tli.cmu.edu";

  # Serves the site over HTTP as well as HTTPS, without a redirect, for old
  # clients that cannot use current TLS.
  services.nginx.virtualHosts."webkilt.andrew.cmu.edu" = {
    addSSL = true;
    enableACME = true;
    root = site;
    # The MCP endpoint is HTTPS only: its clients are current, unlike the
    # site's. A 308 keeps a client's POST. The server answers with plain JSON
    # today; no buffering and a long timeout let it stream later.
    locations."= /mcp" = lib.mkIf (mcpImage != null) {
      proxyPass = "http://127.0.0.1:3001";
      extraConfig = ''
        if ($scheme = http) {
          return 308 https://$host$request_uri;
        }
        proxy_buffering off;
        proxy_read_timeout 1h;
      '';
    };
  };

  # The site's original name, kept for old links: a permanent redirect that
  # keeps the scheme and path. Its own certificate, so neither name depends on
  # the other.
  services.nginx.virtualHosts."webkit.andrew.cmu.edu" = {
    addSSL = true;
    enableACME = true;
    locations."/".return = "308 $scheme://webkilt.andrew.cmu.edu$request_uri";
  };
}
