{ ... }:

{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
  };

  # HTTP-01 challenge needs port 80 reachable; each host's virtualHosts
  # entries set `enableACME = true; forceSSL = true;` to actually issue
  # and terminate certs.
  security.acme.acceptTerms = true;
  # Set a real operational contact before activating a public vhost:
  # security.acme.defaults.email = "<ops-address>";

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
