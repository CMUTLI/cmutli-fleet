# Service documentation

One document per service FQDN describes the production contract shared by its
host pool. It covers routing, persistent storage, runtime units, operational
secrets, deployment, rollback, and service-specific runbooks.

Application repositories remain the source of truth for application behavior:
architecture, development setup, environment-variable semantics, migrations,
and release construction. Fleet documents describe only how a released
application is operated here.
