# Module documentation

This guide describes the shared modules that form a host's NixOS
configuration and links to instructions for optional capabilities.

## Background

Fleet host configurations combine a shared base, host-specific settings, and
profiles for services that host provides. The flake imports the
shared base from `modules/base.nix` for every host. Each host adds its hardware,
disk layout, and machine-specific settings; hosts in the same service pool
import the same service profile.

Capabilities in `modules/capabilities/` are reusable NixOS modules. Import a
capability through a host configuration when it applies to one host, or
through a service profile when it applies to that service pool. Capabilities
imported by the base may still expose options configured per host or service.

## Baseline behavior

The base configuration applies automatically; do not import `modules/base.nix`
again from a host or service profile. It provides the common system packages,
Nix settings and cleanup, compressed swap, log limits, network defaults, and
root password handling.

## Base modules

The flake imports these modules automatically through `modules/base.nix` for
every host.

* **CrowdStrike Falcon**\
  Adds Falcon sensor support using a tenant CID from fleet secrets. The sensor
  is disabled by default; select a tenant and enable it in the host
  configuration to enroll the host.\
  `modules/capabilities/crowdstrike-falcon.nix`\
  See [Set up Falcon](crowdstrike.md).

* **Kerberos**\
  Sets the Andrew realm and PAM defaults used by interactive SSH
  authentication.\
  `modules/capabilities/krb5.nix`\

* **SOPS secrets**\
  Sets the age identity path and selects the host's default secrets file by
  FQDN.\
  `modules/capabilities/secrets.nix`\

* **User baseline**\
  Provides the default human administrator and deploy accounts, along with SSH
  policy.\
  `modules/users/base.nix`\
  See [Baseline behavior](users.md#baseline-behavior).

## Create a module

For a reusable host capability, create a NixOS module at
`modules/capabilities/<capability>.nix` and its guide at
`docs/modules/<capability>.md`. Import the module from `modules/base.nix` if it
applies to every host; otherwise import it from the host configurations or
service profiles that need it. Add an entry in Base modules or Additional
modules and link to the guide in this index.

Describe the capability's purpose and the steps to set it up, provision or
deprovision its resources, and perform recurring tasks as applicable. If the
guide has a table of provisioned choices, such as tenants, explain how to add
and remove entries in the relevant procedures.

## Remove a module

Follow the module guide to deprovision its resources and remove any related
secrets. Remove the module's imports from `modules/base.nix`, host
configurations, and service profiles. Apply the updated configuration to all
affected hosts. Once no configuration imports the module, delete its Nix file
and guide, and remove the guide's link from this index.
