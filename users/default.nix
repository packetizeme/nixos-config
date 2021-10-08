{ config, pkgs, ... }:

{
  users.users.leah = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" ];
    packages = with pkgs; [
      bind
      file
      firefox
      git
      htop
      keepassxc
      mosh
      nmap
      notmuch
      p7zip
      ripgrep
      shellcheck
      tree
      wget
    ];
  };
}
