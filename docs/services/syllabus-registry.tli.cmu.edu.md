# syllabus-registry.tli.cmu.edu

The Syllabus Registry service profile is
`profiles/syllabus-registry.tli.cmu.edu.nix`. Nginx terminates TLS for
`syllabus-registry.tli.cmu.edu` and proxies its current application endpoint
to `127.0.0.1:3001`.

Its container units, persistent-data contract, deployment runbook, and
application-specific documentation remain to be migrated from the existing
Compose deployment.
