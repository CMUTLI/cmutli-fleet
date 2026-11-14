# jekyllandplaid.andrew.cmu.edu

This document describes the production endpoint for the Jekyll & Plaid docs
site as configured by `cmutli-fleet`. The
[application repository](https://github.com/cmu-web/cmu-web-jekyll-and-plaid)
covers the theme, its development and releases.

## Background

Jekyll & Plaid is a Jekyll theme in CMU style, for GitHub Pages sites and, as
the `cmu-web-jekyll-and-plaid` gem, sites built with Jekyll 4. This service
hosts its documentation, a static site with no server of its own. The
service configuration is shared through
`profiles/jekyllandplaid.andrew.cmu.edu.nix` and applied to
`www-01.tli.cmu.edu`. `jekyllandplaid.andrew.cmu.edu` is a CNAME to that host.

## Runtime

Nginx serves the built site from the Nix store. The repository's release
workflow builds the site with the `github-pages` gem, as GitHub Pages does,
and attaches it to each version tag's GitHub release (e.g., `0.1.0`) as
`site.tar.gz`. The
`jekyll-and-plaid-site` flake input pins that file, so changes reach this
service only when the URL in `flake.nix` changes.

## Storage

The service has no persistent data. The site's files are part of the host's
system closure.

## Secrets

The service has no secrets.

## Routing

Nginx terminates TLS for `jekyllandplaid.andrew.cmu.edu`, with a certificate
from ACME. HTTP requests get a 308 to HTTPS.

## Operations

To publish a newer release, change the tag in the `jekyll-and-plaid-site`
input's URL in `flake.nix`, update the input, then
[apply the configuration](../../README.md#apply-configuration):

```console
nix --extra-experimental-features "nix-command flakes" flake update jekyll-and-plaid-site
```
