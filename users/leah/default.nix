{ config, pkgs, ... }:

{
  programs.home-manager.enable = true;
  home.packages = with pkgs; [
    bind
    file
    htop
    mosh
    nmap
    notmuch
    p7zip
    ripgrep
    shellcheck
    tree
    wget
  ];
}
