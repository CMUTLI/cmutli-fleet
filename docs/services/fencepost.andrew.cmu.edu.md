# fencepost.andrew.cmu.edu

This document describes the production endpoint for FencePost as configured
by `cmutli-fleet`. The
[application repository](https://github.com/cmu-web/cmu-web-fencepost)
covers the app, its development and releases.

## Background

FencePost makes link preview images for Carnegie Mellon websites: given a
page, it makes the 1200-by-630 image that shows when someone shares the link,
with the Open Graph tags to go with it. The service configuration is shared
through `profiles/fencepost.andrew.cmu.edu.nix` and applied to
`www-01.tli.cmu.edu`. `fencepost.andrew.cmu.edu` is a CNAME to that host.

FencePost has no release yet, so the profile's `image` is null and the
container and the site are left out.

## Runtime

A rootless Podman container runs as `deploy`, listening on `127.0.0.1:3003`.
The image is pinned by digest in the profile's `image`.

The app fetches the pages it captures, signed out, and refuses private,
loopback and link-local addresses. `www-01.tli.cmu.edu` is on the campus
network (128.2.24.46), so its requests come from a campus address: a page
limited to campus addresses rather than a sign-in is reachable, and can
become a preview. Campus servers have public addresses, so the app's address
check doesn't stop that.

## Storage

The service has no persistent data; a restart loses nothing.

## Secrets

The service has no secrets.

## Routing

Nginx terminates TLS for `fencepost.andrew.cmu.edu`, with a certificate from
ACME, and proxies to the container. HTTP requests get a 308 to HTTPS.

Each preview loads a page in a browser, so Nginx limits requests to two a
second per client address, with a burst of 10 served without delay. Requests
beyond that get a 429.

## Operations

Check health and logs as `deploy`:

```console
sudo -iu deploy
curl --fail --show-error http://127.0.0.1:3003/healthz
journalctl --user -u fencepost
```

To release a new version, update the image digest in the profile, then
[apply the configuration](../../README.md#apply-configuration).
