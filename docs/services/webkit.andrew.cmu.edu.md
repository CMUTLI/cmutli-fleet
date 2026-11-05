# webkit.andrew.cmu.edu

This document describes the production endpoint for the Carnegie Mellon Web Kit
documentation as configured by `cmutli-fleet`. The
[application repository](https://github.com/cmu-web/cmu-web-kit) covers
development, releases, and the kit's other distribution channels.

## Background

The kit is static CSS, JavaScript, and documentation, with no server of its
own. The service configuration is shared through
`profiles/webkit.andrew.cmu.edu.nix` and applied to `www-01.tli.cmu.edu`.
`webkit.andrew.cmu.edu` is a CNAME to that host.

## Runtime

Nginx serves the repository's files from the Nix store. The `cmu-web-kit` flake
input pins a release tag, so changes reach this service only when the tag in
`flake.nix` changes. There is no container.

## Storage

The service has no persistent data. Its files are part of the host's system
closure.

## Secrets

The service has no secrets.

## Routing

Nginx terminates TLS for `webkit.andrew.cmu.edu`, with a certificate from ACME.
The repository's `index.html` sends visitors from `/` to `/docs/`.

## Operations

To publish a newer release, change the tag in the `cmu-web-kit` input in
`flake.nix`, update the input, then
[apply the configuration](../../README.md#apply-configuration):

```console
nix --extra-experimental-features "nix-command flakes" flake update cmu-web-kit
```
