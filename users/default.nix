{ config, pkgs, ... }:

{
  users.users.leah = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" ];
    packages = with pkgs; [
      firefox
      git
      htop
      keepassxc
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
