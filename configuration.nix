# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{
  nixpkgs.config.allowUnfree = true; # Required for NVIDIA driver
  nixpkgs.config.pulseaudio = true;

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "e5b769f7"; # Required for ZFS
  networking.hostName = "bellatrix"; # Define your hostname.

  boot.supportedFilesystems = [ "zfs" ]; # Required for ZFS root

  networking.useDHCP = false;
  networking.interfaces.enp4s0.useDHCP = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Location information
  time.timeZone = secrets.timezone;
  location.latitude = secrets.latitude;
  location.longitude = secrets.longitude;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    vim
    git
    file
    gnupg
    firefox
    keepassxc
    tcpdump
    nmap
    wireshark
    wireshark-cli
    p7zip
    emacs
    shellcheck
    htop
    steam
    steam-run-native
    vlc
    audacity
    discord
    espeak # TTS
    spectacle # KDE screenshots - move this?
    obs-studio
    pinentry-qt
    kwalletcli # provides pinentry-kwallet
  ];

  # This section to allow for yubikey-based SSH key
  # TODO Note: need to set pinentry program in gpg-agent.conf,
  # which isn't handled as part of this config.
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
  environment.shellInit = ''
    export GPG_TTY="$(tty)"
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
  '';

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable U2F support
  hardware.u2f.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Get some rest
  services.redshift.enable = true;

  # File sync
  services.syncthing = {
    enable = true;
    configDir = "/home/leah/.config/syncthing";
    dataDir = "/home/leah/sync";
    user = "leah";
    relay.enable = false;
    openDefaultPorts = true;
  };

  # Use NVIDIA driver
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Allow use of Firefox Plasma integration
  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  # KDE compliains if power management is disabled (per install cd nixpkg)
  powerManagement.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };
  users.mutableUsers = false;
  users.users.root.hashedPassword = secrets.root.hashedPassword;
  users.users.leah = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" ];
    createHome = true;
    home = "/home/leah";
    hashedPassword = secrets.leah.hashedPassword;
    description = "Leah Ives";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}

