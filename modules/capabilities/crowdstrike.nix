{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.cmutli.crowdstrike;
  build = "18708";

  # Each Falcon tenant has its own CID, encrypted only to that tenant's hosts.
  cidFile = inputs."cmutli-fleet-secrets" + "/crowdstrike/${cfg.tenant}.yaml";
  haveCid = builtins.pathExists cidFile;

  # The upstream binaries run unmodified through nix-ld. Patching them would
  # break the sensor's own integrity checks and self-updates.
  falcon-sensor = pkgs.stdenvNoCC.mkDerivation {
    pname = "falcon-sensor";
    version = "7.34.0-${build}";
    src = inputs."cmutli-fleet-vendor"
      + "/crowdstrike/falcon-sensor_7.34.0-${build}_amd64.deb";
    nativeBuildInputs = [ pkgs.dpkg ];
    dontUnpack = true;
    dontFixup = true;
    installPhase = ''
      dpkg-deb -x $src $out
    '';
  };

  # falcond keeps its state beside its binaries and refuses a symlinked
  # /opt/CrowdStrike, so the package is copied into a real directory on every
  # start. A sensor that has already updated itself to a newer build is left
  # alone. Only binaries are copied; the sensor's state files are not in the
  # package.
  #
  # An enrolled sensor keeps its CID. Changing tenants re-enrolls the host as
  # a new Falcon host, so a mismatch is reported rather than corrected.
  install-falcon = pkgs.writeShellScript "install-falcon-sensor" ''
    set -eu
    src=${falcon-sensor}/opt/CrowdStrike
    dst=/opt/CrowdStrike
    ccid=$(cat ${config.sops.secrets.crowdstrike-cid.path})

    if [ -L "$dst" ]; then
      echo "$dst is a symlink; refusing to install" >&2
      exit 1
    fi
    install -d -m 0750 "$dst"

    current=$(readlink "$dst/falcond" 2>/dev/null | sed 's/^falcond//' || true)
    if [ -z "$current" ] || [ "$current" -le ${build} ]; then
      cp -a --remove-destination --no-preserve=ownership "$src/." "$dst/"
      chmod -R u+w,go-w,o-rwx "$dst"
      chmod 0755 "$dst/falcon-flow${build}"
    fi

    for d in Packages Falcon4IT Falcon4IT/bin Falcon4IT/results \
      ASPM ASPM/bin ASPM/results ASPM/tmp; do
      install -d -m 0750 "$dst/$d"
    done

    if enrolled=$("$dst/falconctl" -g --cid 2>/dev/null); then
      want=$(printf '%s' "''${ccid%%-*}" | tr 'A-F' 'a-f')
      case "$enrolled" in
        *"$want"*) ;;
        *) echo "enrolled CID differs from the ${cfg.tenant} tenant CID" >&2 ;;
      esac
    else
      "$dst/falconctl" -s -f --cid="$ccid"
    fi
    "$dst/falconctl" -s -f --backend=bpf
  '';
in
{
  imports = [ ./secrets.nix ];

  options.cmutli.crowdstrike.tenant = lib.mkOption {
    type = lib.types.enum [ "tli" "tli-workstation" "cmu" ];
    default = "tli";
    description = "Falcon tenant whose CID this host enrolls with.";
  };

  config = lib.mkMerge [
    {
      warnings = lib.optional (!haveCid)
        "Falcon sensor disabled: cmutli-fleet-secrets has no crowdstrike/${cfg.tenant}.yaml.";
    }

    (lib.mkIf haveCid {
      sops.secrets.crowdstrike-cid.sopsFile = cidFile;

      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [ libnl openssl zlib ];
      };

      # Absolute paths the sensor and its helper scripts execute.
      systemd.tmpfiles.rules = [
        "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
        "L+ /usr/sbin/systemctl - - - - ${config.systemd.package}/bin/systemctl"
      ] ++ lib.optional config.virtualisation.podman.enable
        "L+ /usr/bin/podman - - - - /run/current-system/sw/bin/podman";

      # Mirrors the unit shipped in the package, with the install step added.
      systemd.services.falcon-sensor = {
        description = "CrowdStrike Falcon Sensor";
        wantedBy = [ "multi-user.target" ];
        after = [ "local-fs.target" ];
        unitConfig = {
          DefaultDependencies = false;
          RequiresMountsFor = [ "/opt" "/var" ];
        };
        conflicts = [ "shutdown.target" ];
        before = [ "shutdown.target" ];
        serviceConfig = {
          Type = "forking";
          ExecStartPre = [ install-falcon "/opt/CrowdStrike/falconctl -g --cid" ];
          ExecStart = "/opt/CrowdStrike/falcond";
          PIDFile = "/run/falcond.pid";
          Restart = "no";
          TimeoutStopSec = "60s";
          KillMode = "control-group";
          KillSignal = "SIGTERM";
          Delegate = true;
        };
      };
    })
  ];
}
