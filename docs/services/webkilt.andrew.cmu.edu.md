# webkilt.andrew.cmu.edu

This document describes the production endpoint for the Carnegie Mellon Web Kit
documentation as configured by `cmutli-fleet`. The
[application repository](https://github.com/cmu-web/cmu-web-kilt) covers
development, releases, and the kit's other distribution channels.

## Background

The kit is static CSS, JavaScript, and documentation, with no server of its
own. The service configuration is shared through
`profiles/webkilt.andrew.cmu.edu.nix` and applied to `www-01.tli.cmu.edu`.
`webkilt.andrew.cmu.edu` and `webkit.andrew.cmu.edu` are CNAMEs to that host.

## Runtime

Nginx serves the repository's files from the Nix store. The `cmu-web-kilt` flake
input pins a release tag, so changes reach this service only when the tag in
`flake.nix` changes. There is no container.

## Storage

The service has no persistent data. Its files are part of the host's system
closure.

## Secrets

The service has no secrets.

## Routing

Nginx serves `webkilt.andrew.cmu.edu` on port 80 as well as 443, without
redirecting HTTP to HTTPS, so old clients that cannot use current TLS still
work. It terminates TLS on 443 with a certificate from ACME.
`webkit.andrew.cmu.edu`, the site's original name, stays as a permanent
redirect: Nginx answers it on both ports with a 301 to the same scheme and
path on `webkilt.andrew.cmu.edu`. Each name has its own ACME certificate.
The repository's `index.html` sends visitors from `/` to `/docs/`.

## Operations

To publish a newer release, change the tag in the `cmu-web-kilt` input in
`flake.nix`, update the input, then
[apply the configuration](../../README.md#apply-configuration):

```console
nix --extra-experimental-features "nix-command flakes" flake update cmu-web-kilt
```
