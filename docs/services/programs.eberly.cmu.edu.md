# programs.eberly.cmu.edu

## Profile

`profiles/programs.eberly.cmu.edu.nix`

## Runtime

- Rails and MySQL run as rootless `deploy` Podman units.
- Nginx terminates TLS and proxies to Rails at `127.0.0.1:3000`.
- MySQL has no host-published port.
- MySQL data is `/srv/programs/mysql`.

## Secrets and identity

- Store database, Rails, and Entra secret values in the private secrets repo.
- Entra registration requires tenant ID, client ID, client secret, scopes,
  claims, and the exact Rails callback URI.

## Pending

- Rails and MySQL image references
- Database names and users
- Quadlet units and health checks
- Backup and restore procedure
