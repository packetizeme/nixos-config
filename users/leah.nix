{ config, pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{
  users.users.leah = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" ];
    createHome = true;
    home = "/home/leah";
    hashedPassword = secrets.leah.hashedPassword;
    description = "Leah Ives";
    shell = pkgs.fish;
    packages = with pkgs; [
      audacity
      discord
      espeak # TTS
      gimp
      gnucash
      hugo
      unstable.keepassxc
      libreoffice
      nmap
      notmuch
      p7zip
      (python3.withPackages(ps: with ps; [ ipython ])) # TODO Understand why "ps: with ps;" is required; what does it do?
      shellcheck
      steam
      steam-run-native
      tree
      unstable.obs-studio
      unstable.obs-v4l2sink # TODO Note: plugin will not be available until manually linked into ~/.config/obs-studio/plugins/
      vlc
      wget
      wine
      wireshark
      wireshark-cli
      zoom-us
    ];
  };
}
