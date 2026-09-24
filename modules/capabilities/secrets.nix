{ config, inputs, ... }:

{
  sops.age.keyFile = "/var/lib/sops-age/identity.txt";
  sops.defaultSopsFile = inputs."cmutli-fleet-secrets" + "/hosts/${config.networking.fqdn}.yaml";
}
