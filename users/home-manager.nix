{config, pkgs, ...}:

{
  imports = [ <home-manager/nixos> ];

  home-manager.users.leah = (import ./leah);
}