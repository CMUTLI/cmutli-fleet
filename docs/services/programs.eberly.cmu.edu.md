# programs.eberly.cmu.edu

## Profile

`profiles/programs.eberly.cmu.edu.nix`

## Runtime

- Nginx terminates TLS and proxies to Rails at `127.0.0.1:3000`.
- Rootless Podman is enabled for `deploy`.
- `/srv/programs` and `/srv/programs/mysql` are prepared for application data.

## Secrets and identity

No application secrets or identity integration are configured yet.
