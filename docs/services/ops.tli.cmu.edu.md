# ops.tli.cmu.edu

## Profile

`profiles/ops.tli.cmu.edu.nix`

## Runtime

- Nginx terminates TLS for `ops.tli.cmu.edu` and proxies to Grafana on
  `127.0.0.1:3000`.
- Grafana runs in rootless Podman as `deploy`. Its data and initial admin
  password are stored below `/srv/ops/grafana`.
- Prometheus and the local node exporter listen only on loopback. Prometheus
  currently scrapes ops-01; remote hosts need a restricted metrics path before
  their exporters can be added.
- Dashboards and Grafana provisioning come from the pinned
  `cmutli-dashboards` flake input.

## Login

On first start, the Grafana unit creates a random admin password. Read it with
`sudo cat /srv/ops/grafana/admin-password`. Grafana uses this file only when it
initializes a new database; changing the password in Grafana does not update
the file. Local accounts remain in use until Entra is configured.

## Deployment

Before deploying, enroll ops-01's age recipient for the fleet root-password
secret as described in `cmutli-fleet-secrets/README.md`. Confirm
`ops.tli.cmu.edu` resolves to the host and HTTP-01 traffic reaches port 80.

Update the dashboards input in `flake.lock` after publishing dashboard changes,
then deploy `ops-01.tli.cmu.edu`. The Prometheus UI is not exposed publicly.
