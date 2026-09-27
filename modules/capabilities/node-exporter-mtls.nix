{ config, inputs, lib, pkgs, ... }:

let
  secretFile = inputs."cmutli-fleet-secrets"
    + "/monitoring/hosts/${config.networking.fqdn}.yaml";
  caCertificate = ../../certs/monitoring-ca.pem;
  available = builtins.pathExists secretFile
    && builtins.pathExists caCertificate;
  webConfig = (pkgs.formats.yaml { }).generate "node-exporter-web.yaml" {
    tls_server_config = {
      cert_file = config.sops.secrets.node-exporter-cert.path;
      key_file = config.sops.secrets.node-exporter-key.path;
      client_ca_file = caCertificate;
      client_auth_type = "RequireAndVerifyClientCert";
      client_allowed_sans = [ "ops.tli.cmu.edu" ];
    };
  };
in
{
  options.cmutli.monitoring.nodeTlsAvailable = lib.mkOption {
    type = lib.types.bool;
    readOnly = true;
    default = available;
  };

  config = lib.mkIf available {
    sops.secrets.node-exporter-cert = {
      sopsFile = secretFile;
      key = "certificate";
      owner = "node-exporter";
      group = "node-exporter";
      mode = "0440";
    };
    sops.secrets.node-exporter-key = {
      sopsFile = secretFile;
      key = "private-key";
      owner = "node-exporter";
      group = "node-exporter";
      mode = "0440";
    };

    services.prometheus.exporters.node = {
      enable = true;
      listenAddress = "0.0.0.0";
      openFirewall = true;
      extraFlags = [ "--web.config.file=${webConfig}" ];
    };
  };
}
