let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOiR3PEEZN8DE6ThxvtScodXSkBsmvt2VD1lDwC59ib6 timmy@Tings-MacBook-Pro.local";
  users = [ user ];
  systems = [ ];
in
{
  #"darwin-syncthing-cert.age".publicKeys = [ timmy ];
  #"darwin-syncthing-key.age".publicKeys = [ timmy ];
  #"felix-syncthing-cert.age".publicKeys = [ timmy ];
  #"felix-syncthing-key.age".publicKeys = [ timmy ];
  "github-ssh-key.age".publicKeys = [ users ];
  "github-signing-key.age".publicKeys = [ users ];
  #"syncthing-gui-password.age".publicKeys = [ timmy ];
}
