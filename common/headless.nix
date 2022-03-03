{ config, pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{

  boot.cleanTmpDir = true;
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2269;
      hostKeys = [ "/persist/secrets/initrd/ssh_host_ed25519_key" ];
      # TODO What would need to change to return [] if leah's keys aren't defined?
      authorizedKeys = config.users.users.leah.openssh.authorizedKeys.keys;
    };
  };

  users.mutableUsers = false;

  nix.useSandbox = true;
  nix.autoOptimiseStore = true;
  nix.gc.automatic = true;
  nix.gc.dates = "*:0/30";
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
  services.zfs.autoScrub.enable = true; # TODO Only set if ZFS is in use

  networking.firewall.enable = true;

  services.chrony.enable = true; # NTP

  services.openssh.enable = true;
  services.openssh = {
    passwordAuthentication = false;
    permitRootLogin = "no";
    openFirewall = false;
    hostKeys = [
      {
        bits = 4096;
        type = "rsa";
        path = "/persist/secrets/ssh/ssh_host_rsa_key";
      }
      {
        type = "ed25519";
        path = "/persist/secrets/ssh/ssh_host_ed25519_key";
      }
    ];
  };

  services.fail2ban.enable = true;

  # TODO Fill this out - saiph has example
  # services.borgbackup.jobs.home = {
  # };
  # services.borgbackup.jobs.persist = {
  # };

}
