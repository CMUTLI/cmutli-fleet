# placemellon.andrew.cmu.edu

This document describes the production endpoint for PlaceMellon as configured
by `cmutli-fleet`. The [application repository](https://github.com/cmu-web/cmu-web-placemellon)
covers development, releases, and [running the image](https://github.com/cmu-web/cmu-web-placemellon/blob/main/DEPLOYMENT.md).

## Background

PlaceMellon returns placeholder photos of Carnegie Mellon at a requested size.
The service configuration is shared through
`profiles/placemellon.andrew.cmu.edu.nix` and applied to `www-01.tli.cmu.edu`.
`placemellon.andrew.cmu.edu` is a CNAME to that host.

## Runtime

A rootless Podman container runs as `deploy`, listening on `127.0.0.1:3000`.
The image is pinned by digest in the profile. It needs outbound HTTPS to CMU
Selects and its image CDN. After a restart, it reloads its catalog, and photo
requests return 503 until the catalog is ready.

## Storage

The service has no persistent data. Rendered images are cached in memory.

## Secrets

The service has no secrets.

## Routing

Nginx terminates TLS for `placemellon.andrew.cmu.edu`, with a certificate from
ACME, and proxies to the container. It serves both HTTP and HTTPS without a
redirect, so `http://` links keep working.

## Operations

Check health and logs as `deploy`:

```console
sudo -iu deploy
curl --fail --show-error http://127.0.0.1:3000/healthz
journalctl --user -u placemellon
```

To release a new version, update the image digest in the profile, then
[apply the configuration](../../README.md#apply-configuration).
