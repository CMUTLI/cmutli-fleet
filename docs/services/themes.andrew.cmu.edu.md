# themes.andrew.cmu.edu

This document describes the production endpoint for the CMU Web themes' docs
as configured by `cmutli-fleet`. Each theme's docs live in their own folder,
with a folder inside it for each Web Kilt line the theme is built on (`0/` is
the current CMU template), as on `webkilt.andrew.cmu.edu`: Forbes & Moreword's
at `/forbes-and-moreword/0/`, Jekyll & Plaid's at `/jekyll-and-plaid/0/`
([its own document](jekyllandplaid.andrew.cmu.edu.md)) and Hunt & Peck's at
`/hunt-and-peck/0/`, with a live demo at `/hunt-and-peck/0/demo/`
([its own document](hunt-and-peck.themes.andrew.cmu.edu.md)). A theme's folder
sends a 307 to its current line, so links name the folder and keep working
when the line changes. The root sends a 302 to the CMU Web home page until the
themes have a page of their own.

The rest of this document covers the Forbes & Moreword docs site. The
[application repository](https://github.com/cmu-web/cmu-web-forbes-and-moreword)
covers the theme, its development and releases.

## Background

Forbes & Moreword is a WordPress block theme in CMU style. This service hosts
its documentation, a WordPress site running the theme. Everything on the site
comes from the repository's `site/` folder: `site/seed.sh` builds the pages,
posts, menu, footer and 404 page with WP-CLI on an empty database when the
image is built. Nothing is
edited in WordPress, so the database holds nothing that isn't in the
repository. The service configuration is shared through
`profiles/themes.andrew.cmu.edu.nix` and applied to
`www-01.tli.cmu.edu`. `themes.andrew.cmu.edu` and the old
`forbesandmoreword.andrew.cmu.edu` point to that host. The site's address,
`https://themes.andrew.cmu.edu/forbes-and-moreword/0`, is built into the
image.

## Runtime

A rootless Podman container runs as `deploy`, listening on `127.0.0.1:3004`.
The image is pinned by digest in the profile's `image`. While `image` is null,
the container and the site are left out. The image holds WordPress (Apache
with PHP), the theme, the site's must-use plugin and the site itself, built
from `site/` with `site/seed.sh` when the image is built. The database is
SQLite, through the WordPress Performance team's SQLite Database Integration
drop-in, so there is no database server.

The container is kept away from everything else on the host. Its root
filesystem is read-only, Apache runs as `www-data` with every capability
dropped and `no-new-privileges`, and it is limited to 512 MB of memory and 256
processes. At start it copies the built database into `/tmp`, a 64 MB tmpfs,
and makes fresh WordPress salts there. It needs no outbound connections;
WordPress blocks its own outgoing requests.

## Storage

The service has no persistent data; a restart puts the site back as built.

## Secrets

The service has no secrets:

- **Salts:** made in memory each time the container starts.
- **Database:** a SQLite file, with no account or password.
- **The admin account:** WordPress requires one. `seed.sh` gives it a random
  password during the image build that is never printed or saved. Nobody
  signs in (see Access).

## Access

Nobody edits this site through the web. All changes are made in the
repository and released.

- **nginx** answers 404 for `/wp-admin/` (including `admin-ajax.php`),
  `/wp-login.php`, `/xmlrpc.php`, `/wp-cron.php` and the REST API (`/wp-json`
  and `?rest_route=`). The site's pages use none of them.
- **The container** answers 404 for the same paths and for any PHP file other
  than `index.php`, in case a request reaches it another way.
- **WordPress** also refuses every sign-in and turns off XML-RPC, application
  passwords and the REST API's user list, through the site's must-use plugin
  (`site/mu-plugins/`). Registration and comments are off, and
  `DISALLOW_FILE_MODS` keeps plugins and themes from being installed or edited.

WP-CLI is in the image, for looking around as `deploy`:

```console
sudo -iu deploy
podman exec forbesandmoreword wp option get blogname
podman exec forbesandmoreword wp post list --post_type=page
```

Anything changed this way is gone at the next restart. Make lasting changes in
the repository's `site/` folder and release them.

## Routing

Nginx terminates TLS for `themes.andrew.cmu.edu`, with a certificate from
ACME, and proxies `/forbes-and-moreword/0/` to the container. HTTP requests
get a 301 to HTTPS. Page requests keep the folders, since WordPress takes its
own address off; requests for files (`wp-content/`, `wp-includes/` and
`images/`) go without them, since Apache in the image keeps them at its root.
Files in the repository's `site/static/images/` (the link preview and gallery
card pictures) are served by the container as they are, at
`/forbes-and-moreword/0/images/`.

`/forbes-and-moreword/` sends a 307 to `/forbes-and-moreword/0/`. Any other
path in the folder but outside a line is a 404, as for every theme.

For now, `forbesandmoreword.andrew.cmu.edu` has its own certificate and sends
a 301 for every request to the same page under
`https://themes.andrew.cmu.edu/forbes-and-moreword/0`.

## Operations

Check health and logs as `deploy`:

```console
sudo -iu deploy
curl --fail --show-error -o /dev/null http://127.0.0.1:3004/
journalctl --user -u forbesandmoreword
```

To publish a new release, update the image digest in the profile, then
[apply the configuration](../../README.md#apply-configuration). Each release's
image rebuilds the site from that release's `site/`.
