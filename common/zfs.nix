{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs = {
    # TODO Move autoscrub to headless config (but only if ZFS is in use)
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      monthly = 3;
    };
  };
}
