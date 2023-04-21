{ pkgs, config, ... }:

{
  environment.systemPackages = with pkgs; [
    firefox
    thunderbird
    keepassxc
    vlc
    mpv
  ];
}
