# Secrets

Encrypted with [sops-nix](https://github.com/Mic92/sops-nix), one file per
host: `secrets/<short-hostname>.yaml`. Each host decrypts with its own age
key, derived from its SSH host key, so there is no fleet-wide decryption key.
The SOPS policy is the repository-root `.sops.yaml`, not a file inside this
directory.

## Adding a host's first secret

1. Provision the host without importing a capability that needs a secret.
   Let it boot at least once so it has an
   `/etc/ssh/ssh_host_ed25519_key`.
2. Verify the host key fingerprint through a trusted channel, then convert
   that key to an age recipient:

   ```console
   ssh-keyscan -t ed25519 <hostname> | ssh-to-age
   ```

3. Add the resulting `age1...` key to the root `.sops.yaml` under a
   `creation_rules` entry matching `secrets/<short-hostname>.yaml`.
4. Edit the secrets file (sops encrypts on save):

   ```console
   sops secrets/<short-hostname>.yaml
   ```

5. Reference the secret from a capability module via
   `sops.secrets.<name>`, then read it at
   `config.sops.secrets.<name>.path` (a runtime-decrypted file, not the
   plaintext value).

The filename must match `config.networking.hostName`, not the host's FQDN.
Review the staged diff before committing: encrypted files should remain
encrypted and `.sops.yaml` should contain no plaintext values.

## What goes here

Only values a host needs to run: database passwords, the CrowdStrike CID,
OAuth client secrets, session secrets, and similar. Public configuration
(hostnames, ports, package lists) belongs in the regular Nix modules, not
here.
