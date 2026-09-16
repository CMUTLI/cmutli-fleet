# programs.eberly.cmu.edu

## Scope

The Programs service runs a Rails application and MySQL database under
rootless Podman. Its service profile is
`profiles/programs.eberly.cmu.edu.nix`; each pool member imports that profile.

## Network and storage

Nginx terminates TLS for `programs.eberly.cmu.edu` and proxies to Rails on
`127.0.0.1:3000`. MySQL data persists at `/srv/programs/mysql`, owned by
`deploy`.

## Runtime and secrets

The Rails and MySQL Quadlet units are not yet defined. Add their image
references, database connection settings, and health checks with the service
implementation. Put secret values in the host's SOPS file; do not commit them
here.

Entra requires a confidential web-application registration. Record the tenant
ID, client ID, approved scopes and claims, and exact redirect URI from the
Rails OmniAuth provider. Store only the client secret in SOPS.

## Operations

Run image pulls and Quadlet restarts in the `deploy` user context; an
administrator enters it locally with `sudo -iu deploy`. The host configuration
and service profile are deployed as an exact Git revision. Application
behavior, migrations, and release construction belong in the Rails repository.
