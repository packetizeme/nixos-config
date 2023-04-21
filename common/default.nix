{ config, pkgs, ... }:

let
  commonSecrets = import ./secrets.nix;
in
{
  nix.settings.sandbox = true;

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  environment.systemPackages = with pkgs; [
    file
    git
    htop
    ripgrep
    tmux
    tree
    vim
  ];

  networking.firewall.enable = true;

  services.chrony.enable = true; # Keep clock in sync (NTP)

  time.timeZone = commonSecrets.timezone;
  location.latitude = commonSecrets.latitude;
  location.longitude = commonSecrets.longitude;
}
