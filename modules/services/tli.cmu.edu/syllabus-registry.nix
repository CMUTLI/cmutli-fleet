{ ... }:

{
  # Import this on every host that runs syllabus-registry so the service
  # definition stays identical across replicas or failover hosts.
  #
  # Caveat: two hosts both terminating ACME/nginx for the same public
  # domain need a plan for who actually holds the certificate and how
  # traffic reaches both (DNS round robin, a load balancer in front, an
  # active/standby split). Not solved here since there is only one host
  # today; whoever adds the second one picks that plan then.
  imports = [
    ../../capabilities/podman.nix
    ../../capabilities/nginx.nix
  ];

  systemd.tmpfiles.rules = [
    "d /srv/syllabus-registry 0750 deploy deploy -"
  ];

  services.nginx.virtualHosts."syllabus-registry.tli.cmu.edu" = {
    forceSSL = true;
    enableACME = true;
    # packages/web (instructor/admin plus Entra sign-in). packages/lti-course
    # (port 3000, LTI launch) likely needs its own location block once the
    # quadlet units exist.
    locations."/" = {
      proxyPass = "http://127.0.0.1:3001";
      proxyWebsockets = true;
    };
  };
}
