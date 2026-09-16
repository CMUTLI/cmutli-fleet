{ ... }:

{
  # Password hashes are disabled. Access is by SSH key or, where enabled,
  # Andrew Kerberos through SSH keyboard-interactive authentication.
  users.mutableUsers = false;

  # CI and deployment automation use this service identity. Podman service
  # units also run as deploy; it may perform privileged deployment actions
  # locally through sudo, but may not authenticate through SSH.
  users.users.deploy = {
    isNormalUser = true;
    uid = 1000;
    description = "";
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
    # TODO: add the CI deploy key once it's generated.
    openssh.authorizedKeys.keys = [ ];
  };

  # Fleet-wide human administrators. Host-specific classes should be added as
  # modules/users/<class>.nix and imported only by the relevant host configs.
  users.users.meribyte = {
    isNormalUser = true;
    uid = 1001;
    description = "";
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCt/s1THeyqDVZJr4OI+msOIjZCbquna8OVgi6EuA3Z5Thg3sNXJkP/ILX/rq0PlS/8Qz62EcDh8uleI0oYEAwMuRBiWroB6fiiD+QW6IxqZE84JFhgH8dx7CTZ7KmHp/dq9bW6LZdN8BGJ9ZYfyHC0O7W7cSpBCYhW+bIz6ERallj5R7m4vrZhgtg3Wo6MIClrSRFWfV1E90DSOMtaAd7hEllg8t/EfzteDV51qahG7JmVcbrPbIkfCUjR2VS+mNnDw/w4bUkPxyJdiU/FjJsIB8LWnwYp5LDXPMs0ax1KG5Z/HCsms3NVIDzm+134NzJWrHwQhYUbXrIenidpE0jjNx3im/5Ze5iBwY2j43XHlJl4fRAga839RgDf5uVTXIeK2wuySllPfNCfa/yXpllWjvWLmsEK+KG8EPhCzykP1o9Lju3zUBlddzeablt/ahcxpA2TFTbVNI/CsOLTmQF+xm5tnK2Y1CB3kXOfoCikWNEZnxNbMY26Ac2lYXKv4xzOI/i8Yso8pqVXqAxpVY45rCDTWGIbKVxujoLQdslfoaTphFRcqlhePc2Up3BxrtVa4thfJjIco/M52LJ34Ek5eZpU69WHBlS5QY8xBaYmJPkrJIILBOzuP3yTR68kAeG3pJjlnFg5+9ptw5LjEe2tWy6NXd/pmH8r26ELf9VnjQ=="
    ];
  };

  users.users.martinv = {
    isNormalUser = true;
    uid = 1002;
    description = "";
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7yNpLkSPnC6npmd4w/reGZPPTS/XNyuUe2NlgRFV0Rio/ubJTEA/pmF35UMLJZmcctoVsMUgU7kk6/t7i0hdTMyPX53qfCEj5KOKN1mtyiuivXEyCojJGr1L5TkYOEOSWbuxXbAalbrE7g2NffoFIEG/r103MCOxKe+VAu5yKSfAhEIavX4IqyoT0jtn/Rdm6ag5KGVmnU4ljOY80yhsRviTbgMmw6/Mqi3CxOc6ZZaIyoeFdXZx1z8GDk962uQYB1if7epBdemlhsW6Rjuho6OSC+SDnFKb9Kz6U9t8UeQkBsVtJqWbt5OAoFaMOfQOBslmHFbIlqYBkApb7RSUJ"
    ];
  };

}
