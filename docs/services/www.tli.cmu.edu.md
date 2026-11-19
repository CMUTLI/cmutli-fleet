# www.tli.cmu.edu

This document describes the production endpoint for TLI's login pages as
configured by `cmutli-fleet`. The
[application repository](https://github.com/CMUTLI/cmutli-login-pages)
covers the pages and their releases.

## Background

TLI's login pages are static pages that send people on to a service's real
sign-in, one button for each way in. They hold no accounts and do no
authentication (that's `cmutli-shib-proxy`). The first is learning.cmu.edu's,
at `https://www.tli.cmu.edu/login/learning/`. The service configuration is
shared through `profiles/www.tli.cmu.edu.nix` and applied to
`www-01.tli.cmu.edu`. `www.tli.cmu.edu` is a CNAME to that host, and
`tli.cmu.edu` has an A record for it.

Only `/login/` comes from the login pages. The site's root is reserved for
whatever `www.tli.cmu.edu` becomes. For now, the root of both names sends a
302 to TLI's website (`https://www.cmu.edu/tli-office/`), and other
addresses on `tli.cmu.edu` get a 301 to the same address on
`www.tli.cmu.edu`.

## Runtime

Nginx serves the repository's `login/` folder from the Nix store, and
nothing else from the repository (no README or workflows). Any
other address gets the login pages' own `login/404.html`. The
`cmutli-login-pages` flake input pins a release tag (e.g., `0.1.0`), so
changes reach this service only when the tag in `flake.nix` changes. The
pages load CMU's template and the Carnegie Mellon Web Kilt from their own
hosts.

## Storage

The service has no persistent data. The pages are part of the host's system
closure.

## Secrets

The service has no secrets.

## Routing

Nginx terminates TLS for `www.tli.cmu.edu` and `tli.cmu.edu`, with one
certificate from ACME that covers both names. HTTP requests get a 301 to
HTTPS, except ACME challenges.

## Operations

To publish a newer release, change the tag in the `cmutli-login-pages`
input's URL in `flake.nix`, update the input, then
[apply the configuration](../../README.md#apply-configuration):

```console
nix --extra-experimental-features "nix-command flakes" flake update cmutli-login-pages
```

## Moving learning.cmu.edu's Login Page Here

The page used to be a copy at `https://www.eberly.cmu.edu/login/learning.html`
on the Eberly web server, which isn't in this fleet. After the first deploy:

1. In learning.cmu.edu's Canvas authentication settings, change the discovery
   URL to `https://www.tli.cmu.edu/login/learning/`.
2. On the Eberly web server, redirect `/login/learning.html` to
   `https://www.tli.cmu.edu/login/learning/`.
