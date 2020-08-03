# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{
  nixpkgs.config.pulseaudio = true;

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "97b06e88"; # Required for ZFS
  networking.hostName = "handy"; # Define your hostname.

  boot.supportedFilesystems = [ "zfs" ]; # Required for ZFS root

  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.wlp1s0.useDHCP = true;
  networking.networkmanager.enable = true;

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
    vlc
    pinentry-qt
    spectacle # KDE screenshots
    kwalletcli # provides pinentry-kwallet
    gwenview # KDE Image viewer
    okular # KDE PDF reader
    wine
    isync
    tree
    python3
    (python3.withPackages(ps: with ps; [ ipython ])) # TODO Understand why "ps: with ps;" is required; what does it do?
    notmuch
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
    sway.enable = true;
  };
  environment.shellInit = ''
    export GPG_TTY="$(tty)"
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
  '';

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # I am accelerated
  hardware.opengl.enable = true;

  # Enable U2F support
  hardware.u2f.enable = true;

  # Enable Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # CPU joy
  hardware.cpu.intel.updateMicrocode = true;

  # Power management
  services.thermald.enable = true;
  services.tlp.enable = true;

  # Keep clock in sync (NTP)
  services.chrony.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.monitorSection = ''
    Option "Rotate" "right"
  '';

  # Get some rest
  services.redshift.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Allow use of Firefox Plasma integration
  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  # KDE compliains if power management is disabled (per install cd nixpkg)
  powerManagement.enable = true;

  # Add the fish shell
  programs.fish.enable = true;

  # User accounts
  users.mutableUsers = false;
  users.users = {
    root.hashedPassword = secrets.root.hashedPassword;
    leah = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" "audio" ];
      createHome = true;
      home = "/home/leah";
      hashedPassword = secrets.leah.hashedPassword;
      description = "Leah Ives";
      shell = pkgs.fish;
    };
  };

  # Version of NixOS initially installed
  system.stateVersion = "20.03";

}

