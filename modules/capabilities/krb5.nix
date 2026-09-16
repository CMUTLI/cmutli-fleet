{ ... }:

{
  security.krb5 = {
    enable = true;
    settings = {
      libdefaults = {
        default_realm = "ANDREW.CMU.EDU";
      };
      realms = {
        "ANDREW.CMU.EDU" = {
          admin_server = "kerberos.andrew.cmu.edu";
          default_domain = "andrew.cmu.edu";
        };
      };
    };
  };

  security.pam.krb5.enable = true;
}
