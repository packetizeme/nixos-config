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
  nixpkgs = {
    config = {
      packageOverrides = pkgs: {
        unstable = import unstableTarball {
          config = config.nixpkgs.config;
        };
      };
      allowUnfree = true; # Required for NVIDIA driver
      pulseaudio = true;
    };
  };

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./v4l2loopback.nix
    ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ]; # Required for ZFS root
  };

  networking = {
    hostName = "bellatrix";
    hostId = "e5b769f7"; # Random host ID, required for ZFS

    # Don't use DHCP except on our regular network interface
    useDHCP = false;
    interfaces.enp5s0.useDHCP = true;
  };

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
    borgbackup # TODO research the borgbackup service for configuration
    emacs
    file
    firefox
    git
    gnupg
    gwenview # KDE Image viewer
    htop
    isync
    kwalletcli # provides pinentry-kwallet
    ntfs3g
    okular # KDE PDF reader
    pinentry-qt
    python3
    spectacle # KDE screenshots
    tcpdump
    vim
    virt-manager
  ];

  # Relocate nixos config using symlink
  environment.etc."nixos" = {
    source = "/home/leah/code/nixos/";
  };

  # Enable automatic updates
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;

  nix = {
    gc = {
      automatic = true; # Enable automatic garbage collection
      dates = "*:0/30"; # Run garbage collector every half hour
    };
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemuRunAsRoot = false;
    };
    docker.enable = true;
  };

  # docker-containers = {};

  services = {
    pcscd.enable = true; # Smartcard daemon, used for yubikey GPG
    udev.packages = [ pkgs.yubikey-personalization ]; # Handle yubikey nicely
    printing.enable = true; # Enable CUPS
    chrony.enable = true; # Keep clock in sync (NTP)
    redshift.enable = true; # Color shift in hopes of getting better sleep

    xserver = {
      enable = true;
      layout = "us";
      videoDrivers = [ "nvidia" ]; # Use NVIDIA driver
      displayManager.sddm.enable = true; # Nice logon
      desktopManager.plasma5.enable = true; # Enable KDE
    };

    # TODO: Move file sync to user config
    # File sync
    syncthing = {
      enable = true;
      configDir = "/home/leah/.config/syncthing";
      dataDir = "/home/leah/sync";
      user = "leah";
      relay.enable = false;
      openDefaultPorts = true;
    };
  };

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

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable U2F support
  hardware.u2f.enable = true;

  # Steam fixes from nixpkgs#86480
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };
  hardware.pulseaudio.support32Bit = config.hardware.pulseaudio.enable;

  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true; # KDE browser integration

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
      packages = with pkgs; [
        audacity
        discord
        espeak # TTS
        gimp
        gnucash
        hugo
        keepassxc
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
  };

  # Version of NixOS initially installed
  system.stateVersion = "20.03";

}
