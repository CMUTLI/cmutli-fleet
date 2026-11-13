# qrnegie.andrew.cmu.edu

This document describes the production endpoint for QRnegie as configured by
`cmutli-fleet`. The [application repository](https://github.com/cmu-web/cmu-web-qrnegie)
covers development, releases, and [running the image](https://github.com/cmu-web/cmu-web-qrnegie/blob/main/DEPLOYMENT.md).

## Background

QRnegie draws QR codes in Carnegie Mellon styles, as SVG or PNG. It serves
its documentation and builder at `/`, images at `/qr.svg` and `/qr.png`, the
list of icon names the builder offers at `/icons.json`, and an MCP server at
`/mcp`. The service configuration is shared through
`profiles/qrnegie.andrew.cmu.edu.nix` and applied to `www-01.tli.cmu.edu`.
`qrnegie.andrew.cmu.edu` is a CNAME to that host.

## Runtime

A rootless Podman container runs as `deploy`, listening on `127.0.0.1:3002`.
The image is pinned by digest in the profile's `image`. While `image` is null,
the container and the site are left out. The app needs no outbound
connections: the icons a code can carry are Bootstrap Icons SVG files inside
the image (`bootstrap-icons`, MIT), each read the first time a code uses it
and then kept in memory. Its `PUBLIC_URL` defaults to
`https://qrnegie.andrew.cmu.edu`, the origin the MCP server's image addresses
use, so the profile doesn't set it.

The builder's map runs in the visitor's browser, not on the server. It loads
Leaflet (BSD-2) from cdnjs the first time someone opens the map, and the
browser fetches OpenStreetMap tiles from `tile.openstreetmap.org`, credited on
the map. Address suggestions come from Photon (`photon.komoot.io`), which
searches OpenStreetMap data. Every page also loads the CMU Web Google
Analytics tag from `www.googletagmanager.com`; images and `/mcp` aren't
counted, so the Nginx logs remain the record of those. None of it passes
through QRnegie's server, and Nginx adds no Content-Security-Policy that would
block these hosts.

## Storage

The service has no persistent data; a restart loses nothing.

## Secrets

The service has no secrets.

## Routing

Nginx terminates TLS for `qrnegie.andrew.cmu.edu`, with a certificate from
ACME, and proxies to the container. HTTP requests get a 308 to HTTPS, which
keeps a POST to `/mcp` a POST.

Each image is drawn on request, so Nginx limits `/qr.svg` and `/qr.png` to
five requests a second per client address, with a burst of 20 served without
delay. Requests beyond that get a 429. The builder redraws at most twice a
second, so ordinary use stays well under the limit. The documentation, the
builder, `/icons.json`, and `/mcp` are not limited.

## Operations

Check health and logs as `deploy`:

```console
sudo -iu deploy
curl --fail --show-error http://127.0.0.1:3002/healthz
curl --fail --show-error 'http://127.0.0.1:3002/qr.png?text=https%3A%2F%2Fwww.cmu.edu%2F' -o /dev/null
journalctl --user -u qrnegie
```

`/healthz` doesn't draw a code, so the second command checks an image too.

To release a new version, update the image digest in the profile, then
[apply the configuration](../../README.md#apply-configuration).
