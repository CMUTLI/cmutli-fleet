# Kith & Kirr on themes.andrew.cmu.edu

Kith & Kirr is a CMU look for Grouper's web UI
([repository](https://github.com/cmu-web/cmu-web-kith-and-kirr)). This
service serves its docs at `https://themes.andrew.cmu.edu/kith-and-kirr/0/`
and a live demo, a read-only Grouper wearing the theme, at
`https://themes.andrew.cmu.edu/kith-and-kirr/0/demo/`. The configuration is
`profiles/kith-and-kirr.themes.andrew.cmu.edu.nix`, imported by
`profiles/themes.andrew.cmu.edu.nix` on `www-01.tli.cmu.edu`.

It has nothing to do with any real Grouper: its own containers, database
and made-up people, and no network access beyond its own web server.

## Releases

Two flake inputs name a release: the repository at the tag (the theme in
`grouper/`, the demo's settings in `demo/`, and the loader and subject
source in `dev/`) and the release's built docs site (`site.tar.gz`, built
for `/kith-and-kirr/0`). Without them the profile adds nothing. To move to a
new release, change both tags in `flake.nix`, run
`nix flake update kith-and-kirr kith-and-kirr-site`, commit and deploy
`www-01`.

## The Demo

Three rootless containers run as `deploy`: Postgres, Grouper 7.9.1's UI and
an nginx in front, each pinned by digest.

- **One visitor.** The demo's nginx signs every request in as Andrew
  Carnegie (`ac00`), a made-up person in the demo's viewer group, who can
  see every folder, group and member and change nothing. It sets
  `X-Remote-User` itself, replacing any a browser sends.
- **Read-only.** Grouper runs with `grouper.api.readonly = true`: every
  change through the UI, web services or GSH fails, even for Grouper's own
  system account.
- **No way out.** Postgres and Grouper are only on an internal Podman
  network; the demo's nginx is on it and on a second network for its port,
  `127.0.0.1:3006`, which the host's nginx proxies to.
- **Its address.** Grouper's UI reads only an address's first folder as its
  own, so it runs at `/grouper/` and the demo's nginx maps
  `/kith-and-kirr/0/demo/` onto it, along with Grouper's redirects and its
  cookie's path. Grouper's pages use relative addresses.
- **Not indexed:** `X-Robots-Tag: noindex, nofollow` on every demo page.
- **Memory:** Grouper takes up to 1 GB (768 MB for Java), Postgres 256 MB
  and nginx 64 MB.

### Settings

Grouper's settings are built from the release when the system is built:
the theme's lines, sign-in by `X-Remote-User`, the demo's tagline, and
`grouper.properties` from `demo/groups.yaml`'s settings (written by the
loader, as `make run` does in development), once writable and once with
`demo/grouper.properties` added. A small start script copies them into
Grouper's `WEB-INF/classes`, adds the theme's CSRFGuard line to the file
Grouper ships, and starts Grouper.

### The Nightly Rebuild

Grouper's own scheduled jobs can't rebuild a read-only Grouper, so a user
timer, `kith-and-kirr-demo-rebuild`, runs at 3 a.m.: it stops the demo,
deletes the database's volume, starts Grouper writable (a flag file in
`~deploy/.local/state/kith-and-kirr-demo/`), loads `demo/groups.yaml` with
the loader the repository's `make seed` runs (`dev/load.py`) and waits for
its checks, then restarts Grouper read-only and the demo's nginx. The demo
is down for those few minutes. If Grouper doesn't answer within 10 minutes,
or the checks still fail after 10 more, the rebuild stops with an error; the
demo then comes back empty until the rebuild runs again.

After the first deploy, build the demo once by hand:

```console
sudo -u deploy XDG_RUNTIME_DIR=/run/user/$(id -u deploy) systemctl --user start kith-and-kirr-demo-rebuild
```

Its output, including the checks, is in
`journalctl --user -u kith-and-kirr-demo-rebuild` (as `deploy`), and the
loader's GSH logs in `~deploy/.local/state/kith-and-kirr-demo/`.
