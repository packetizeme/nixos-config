{ config, pkgs, ... }:

{
  users.users.leah = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" ];
    packages = with pkgs; [
      firefox
      git
      keepassxc
    ];
  };
}
