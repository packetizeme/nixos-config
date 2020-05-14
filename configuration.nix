# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  secrets = import ./secrets.nix;
  unstableTarball =
    fetchTarball
      https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz;
in
{
  nixpkgs.config.packageOverrides = pkgs: {
    unstable = import unstableTarball {
      config = config.nixpkgs.config;
    };
  };
  nixpkgs.config.allowUnfree = true; # Required for NVIDIA driver
  nixpkgs.config.pulseaudio = true;

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./v4l2loopback.nix
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
    unstable.obs-studio
    unstable.obs-v4l2sink # TODO Note: plugin will not be available until manually linked into ~/.config/obs-studio/plugins/
    pinentry-qt
    virt-manager
    zoom-us
    spectacle # KDE screenshots
    kwalletcli # provides pinentry-kwallet
    gwenview # KDE Image viewer
    wine
    isync
    tree
  ];

  virtualisation = {
    libvirtd = {
      enable = true;
      qemuRunAsRoot = false;
    };
  };

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

  # Steam fixes from nixpkgs#86480
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };
  hardware.pulseaudio.support32Bit = config.hardware.pulseaudio.enable;

  # Get some rest
  services.redshift.enable = true;

  # File sync
  # TODO Move into user-specific config?
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

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Allow use of Firefox Plasma integration
  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  # KDE compliains if power management is disabled (per install cd nixpkg)
  powerManagement.enable = true;

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
    };
  };

  # Version of NixOS initially installed
  system.stateVersion = "20.03";

}

