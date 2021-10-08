{ config, pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{
  nix.useSandbox = true;

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
    tree
    vim
  ];

  networking.firewall.enable = true;

  services.chrony.enable = true; # Keep clock in sync (NTP)

  time.timeZone = secrets.timezone;
  location.latitude = secrets.latitude;
  location.longitude = secrets.longitude;
}
