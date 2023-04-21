{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs = {
    autoSnapshot = {
      enable = true;
      monthly = 3;
    };
  };
}
