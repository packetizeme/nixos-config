{ pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{
  users.users.leah = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "wheel"
      "audio"
      "libvirtd"
      "dialout"
    ];
    hashedPassword = secrets.leah.hashedPassword;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrQux0uRRIIqupWbl43o7+KJyedPCDD/vYlbG9+aDfQ leah"
    ];

    shell = pkgs.fish;

    packages = with pkgs; [
      bind # Provides nslookup, dig
      bat
      file
      git
      htop
      jq
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
      xsv
      fish
    ];
  };
}
