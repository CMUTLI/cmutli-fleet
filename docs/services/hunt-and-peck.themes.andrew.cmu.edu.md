# Hunt & Peck on themes.andrew.cmu.edu

Hunt & Peck is a CMU look for Vaultwarden's web vault
([repository](https://github.com/cmu-web/cmu-web-hunt-and-peck)). This
service serves its docs at `https://themes.andrew.cmu.edu/hunt-and-peck/0/`
and a live demo, a Vaultwarden wearing the theme, at
`https://themes.andrew.cmu.edu/hunt-and-peck/0/demo/`. The configuration is
`profiles/hunt-and-peck.themes.andrew.cmu.edu.nix`, imported by
`profiles/themes.andrew.cmu.edu.nix` on `www-01.tli.cmu.edu`.

It has nothing to do with `vault.tli.cmu.edu`, TLI's real password manager:
a separate container, image pin, port and data, and no shared secrets.

## Turning It On

The profile adds nothing until Hunt & Peck has a release and two flake
inputs name it: the repository at the tag, for the theme the demo wears, and
the release's built docs site (`site.tar.gz`, built with Docs & Donner).
After the release, add to `flake.nix`'s inputs:

```nix
hunt-and-peck = { url = "github:cmu-web/cmu-web-hunt-and-peck/0.1.0"; flake = false; };
hunt-and-peck-site = {
  url = "https://github.com/cmu-web/cmu-web-hunt-and-peck/releases/download/0.1.0/site.tar.gz";
  flake = false;
};
```

then `nix flake update hunt-and-peck hunt-and-peck-site`, commit and deploy
`www-01`. To move to a new release, change both tags and update both
inputs.

## The Demo

Every visitor signs in to the same made-up account, Andrew Carnegie
(`ac00@andrew.cmu.edu`), with the password Hunt & Peck's docs publish. So the
demo is built to hold nothing and keep nothing:

- **Read-only at the edge.** nginx passes only GET and HEAD to Vaultwarden,
  plus the requests that sign in (`identity/connect/token`, the prelogin
  requests and the notifications handshake). Changing the password, turning
  on two-step login, deleting the account, saving an item or creating a
  Send are refused with 403 before Vaultwarden sees them. `/admin` is 404.
- **Nothing on disk.** The container's root is read-only and its data is a
  64 MB tmpfs. At each start it copies the seed,
  `profiles/hunt-and-peck-demo/seed.sqlite3`, into memory. A timer restarts
  it at 4 a.m. every night, and any restart puts it back as seeded.
- **Vaultwarden's own limits:** sign-ups, invitations, Sends, emergency
  access, organizations, attachments, password hints and icon downloads are
  off. `ADMIN_TOKEN` is unset, which turns the admin page off. No mail, no
  single sign-on.
- **Kept small:** every capability dropped, `no-new-privileges`, 256 MB of
  memory, 128 processes, on `127.0.0.1:3005`.
- **Not indexed:** Vaultwarden sends `X-Robots-Tag: noindex, nofollow` on
  every demo page.

Sign-ins still add a device record each time; they live in memory until the
nightly reset.

## The Seed

`scripts/hunt-and-peck-demo-seed.py` makes the seed with Hunt & Peck's own
test helpers: it runs the pinned Vaultwarden with sign-ups on, on loopback
only, makes the account and items, and copies out the database with its
devices removed. Run it from a Hunt & Peck checkout's test environment
(Python with `test/requirements.txt` and Playwright's Chromium, Node, Docker
or Podman):

```console
python3 scripts/hunt-and-peck-demo-seed.py ../cmu-web-hunt-and-peck
```

Vaultwarden migrates an older seed itself when it starts, so a Vaultwarden
upgrade doesn't need a new seed unless the demo fails to start.

## Fonts

The theme loads Open Sans from `/cmu-web/fonts/` on the web vault's own
site, which its Content Security Policy requires. nginx serves the theme's
fonts at that path at the host's root, so the demo needs no theme setting of
its own. The web vault also asks for its welcome dialog's picture at
`/images/welcome-dialog-graphic.png`, outside its folder; nginx sends that
one request to the demo.
