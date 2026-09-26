{ ... }:

{
  users.users.meribyte = {
    isNormalUser = true;
    uid = 1001;
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+3OlnHJ5PmM0GTvvuzmk+rKQNmjtV0D9bGVFjPXdSe meribyte@hackwrench tli"
    ];
  };

  users.users.martinv = {
    isNormalUser = true;
    uid = 1002;
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7yNpLkSPnC6npmd4w/reGZPPTS/XNyuUe2NlgRFV0Rio/ubJTEA/pmF35UMLJZmcctoVsMUgU7kk6/t7i0hdTMyPX53qfCEj5KOKN1mtyiuivXEyCojJGr1L5TkYOEOSWbuxXbAalbrE7g2NffoFIEG/r103MCOxKe+VAu5yKSfAhEIavX4IqyoT0jtn/Rdm6ag5KGVmnU4ljOY80yhsRviTbgMmw6/Mqi3CxOc6ZZaIyoeFdXZx1z8GDk962uQYB1if7epBdemlhsW6Rjuho6OSC+SDnFKb9Kz6U9t8UeQkBsVtJqWbt5OAoFaMOfQOBslmHFbIlqYBkApb7RSUJ"
    ];
  };
}
