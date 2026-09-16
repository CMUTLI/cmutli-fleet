{ ... }:

{
  imports = [ ./secrets.nix ];

  # The CrowdStrike CID differs per host, so it lives in that host's own
  # secrets/<host>.yaml under this key rather than being hardcoded here.
  sops.secrets.crowdstrike-cid = { };

  # TODO: package falcon-sensor for NixOS. It ships as a proprietary .deb
  # with a kernel component, built for an FHS layout under /opt/CrowdStrike,
  # and won't run unmodified here. This needs its own derivation
  # (autoPatchelfHook, possibly a buildFHSEnv for whatever resists
  # patching) once we have a package to build against; not attempted in
  # this stub.
  #
  # Once packaged, this module should end up looking roughly like:
  #   systemd.services.falcon-sensor = { ... };
  #   environment.etc."CrowdStrike/cid".source =
  #     config.sops.secrets.crowdstrike-cid.path;
}
