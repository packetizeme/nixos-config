{ config, pkgs, ... }:

{
  users.users.leah = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "wheel"
      "audio"
      "libvirtd"
    ];
    packages = with pkgs; [
      bind # Provides nslookup, dig
      file
      git
      htop
      mosh
      nmap
      notmuch
      p7zip
      ripgrep
      shellcheck
      tcpdump
      tree
      wget
      whois
    ];
  };
}
