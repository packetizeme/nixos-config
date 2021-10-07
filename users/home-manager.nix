{ config, pkgs, ... }:

{
  # Note: home-manager channel must be added to the system manually before this will work.
  # TODO: Figure out how to bootstrap home-manager from NixOS configuration
  imports = [ <home-manager/nixos> ];

  home-manager.users.leah = (import ./leah);
}
