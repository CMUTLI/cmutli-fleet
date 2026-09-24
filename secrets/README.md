# Secrets

No secret files belong in this public repository.

Use private `CMUTLI/cmutli-fleet-secrets` for SOPS-encrypted host files,
recipient policy, and hybrid age identity bootstrap. Keep secret values out of
Nix modules, GitHub Actions logs, command arguments, and the Nix store.
