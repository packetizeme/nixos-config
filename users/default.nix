{ config, ... }:

let
  secrets = import ./secrets.nix;
in
{
  imports = [ ./leah.nix ];
  users.users.root.hashedPassword = secrets.root.hashedPassword;
}
