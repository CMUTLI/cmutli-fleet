# syllabus-registry.tli.cmu.edu

## Profile

`profiles/syllabus-registry.tli.cmu.edu.nix`

## Runtime

- Nginx terminates TLS and proxies to `127.0.0.1:3001`.
- Rootless Podman is enabled for `deploy`.
- The fleet does not yet declare application units or persistent storage.
