{ config, pkgs, ...}:

{
  imports = [
    #./email.nix
  ];

  services.lorri.enable = false;
  programs.direnv.enable = true;
  programs.direnv.enableFishIntegration = true;
  
  home.packages = with pkgs; [
    bind
    file
    git
    gmni # gemini browser
    htop
    jq
    mosh
    nixfmt
    nmap
    p7zip
    ripgrep
    shellcheck
    tcpdump
    tree
    wget
    whois
  ];

  home.stateVersion = "22.05";
  #manual.manpages.enable = false;

  programs.home-manager.enable = true;
}
