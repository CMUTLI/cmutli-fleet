# webkilt.andrew.cmu.edu

This document describes the production endpoint for the Carnegie Mellon Web Kilt
documentation as configured by `cmutli-fleet`. The
[application repository](https://github.com/cmu-web/cmu-web-kilt) covers
development, releases, and the kit's other distribution channels. The
[MCP server's repository](https://github.com/cmu-web/cmu-web-kilt-mcp) covers
the server and its image.

## Background

The kit is static CSS, JavaScript, and documentation, with no server of its
own. The kit's MCP server, which answers questions about the kit's components
and checks markup against it, runs beside the site at `/mcp`. The service
configuration is shared through `profiles/webkilt.andrew.cmu.edu.nix` and
applied to `www-01.tli.cmu.edu`.
`webkilt.andrew.cmu.edu` and `webkit.andrew.cmu.edu` are CNAMEs to that host.

## Runtime

Nginx serves the repository's files from the Nix store. The kit has one
release line per CMU template, each with its own docs: line 0 is the current
template. The profile's `lines` maps each line's number to a flake input, and
`cmu-web-kilt` is line 0's. Each input pins a release tag, so changes reach
this service only when a tag in `flake.nix` changes.

The MCP server is a rootless Podman container running as `deploy`, listening
on `127.0.0.1:3001`. Its image is pinned by digest in the profile's
`mcpImage`. While `mcpImage` is null, the container and the `/mcp` route are
left out. The server reads each kit release from jsDelivr, so it needs
outbound HTTPS, and a new kit release reaches it without a deploy. It links
each release to its line's docs on this site, which is its default
`DOCS_URL`.

The server's `generate_social_card` tool makes link preview images: it
captures a public page with Chromium, or takes an uploaded screenshot, and
returns the image without storing it. Its captures come from
`www-01.tli.cmu.edu`, on the campus network, so a page limited to campus
addresses rather than a sign-in can be captured, as with
[FencePost](fencepost.andrew.cmu.edu.md#runtime).

## Storage

The service has no persistent data. The site's files are part of the host's
system closure. The MCP server caches kit releases in memory.

## Secrets

The service has no secrets.

## Routing

Nginx serves `webkilt.andrew.cmu.edu` on port 80 as well as 443, without
redirecting HTTP to HTTPS, so old clients that cannot use current TLS still
work. It terminates TLS on 443 with a certificate from ACME.
`webkit.andrew.cmu.edu`, the site's original name, stays as a permanent
redirect: Nginx answers it on both ports with a 308 to the same scheme and
path on `webkilt.andrew.cmu.edu`. Each name has its own ACME certificate.
Each line's documentation is at its number, such as `/0/`, with that line's
CSS and JavaScript beside it, as the kit's GitHub Pages workflow lays them
out. There's no switcher between lines. The site's root gets a 307 to the
line that the profile's `rootLine` names. The redirect is temporary so that
browsers and search engines follow `rootLine` when it changes. Pages don't
carry over between lines, so nothing else redirects: any other path outside a
line, such as a link from before the lines like `/forms.html`, is a 404. Two
paths stay at the root: `/mcp`, and `/images/cmu-web-preview.webp`, the
image the other CMU Web sites show on the kit's card, which is the root
line's copy.

This site is Nginx's default on the host: a request for a name that no site
claims, such as a CNAME for a service not released yet, gets the kit's docs.
Over HTTPS that request still sees this site's certificate, so browsers warn
that the name doesn't match.

`https://webkilt.andrew.cmu.edu/mcp` proxies to the MCP server. The server
answers each request with plain JSON; the proxy is unbuffered so it could
stream later. It accepts request bodies of up to 12 MB, for uploaded
screenshots. Unlike the site, `/mcp` is HTTPS only: an HTTP request gets a 308
to HTTPS, which keeps its POST.

## Operations

To publish a newer release, change the tag in that line's input in
`flake.nix`, update the input, then
[apply the configuration](../../README.md#apply-configuration):

```console
nix --extra-experimental-features "nix-command flakes" flake update cmu-web-kilt
```

To add a line, add a flake input pinned to the line's first release tag and
add it to `lines` in the profile. To send the root to it, set `rootLine`.

To release a new version of the MCP server, set `mcpImage` in the profile to
the new image digest, then apply the configuration. Check its health and logs
as `deploy`:

```console
sudo -iu deploy
curl --fail --show-error http://127.0.0.1:3001/healthz
journalctl --user -u webkilt-mcp
```
