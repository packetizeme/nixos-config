{ config, pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = secrets.timezone;

  # Networking
  networking = {
    hostName = "mira"; # Define your hostname.
    hostId = "6267c547"; # Needs to be defined to make ZFS happy
    # wireless.enable = true; # Enables wireless support via wpa_supplicant
    networkmanager.enable = true;
    useDHCP = false;
    # Disabled interface-specific useDHCP because it delays boot significantly
    # This is addressed by network manager without setting things here.
    interfaces.enp133s0.useDHCP = false;
    interfaces.wlp170s0.useDHCP = false;
  };


  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    desktopManager.plasma5.enable = true;
    desktopManager.gnome.enable = true;
    windowManager.i3.enable = true;
  };

  # gnome3 and KDE cannot coexist without some nudging
  # force use of a specific askPassword program or Nix will barf
  # programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.plasma5.ksshaskpass.out}/bin/ksshaskpass"; 
  # The above (^) barfed too. Let's try disabling one of the sources of conflict.
  programs.seahorse.enable = false;
  programs.ssh.startAgent = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  users.users.leah = {
    isNormalUser = true;
    uid = 1000;
    hashedPassword = secrets.leah.hashedPassword;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      p7zip
      ripgrep
      shellcheck
      notmuch
      tree
      firefox
      wget
      nmap
      keepassxc
      git
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
  ];

  services = {
    openssh.enable = false;
    syncthing = {
      enable = true;
      configDir = "/home/leah/.config/syncthing";
      dataDir = "/home/leah/sync";
      user = "leah";
      relay.enable = false;
      openDefaultPorts = false;
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # Taken from Graham Christen's post on NixOS on the framework laptop
  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.fprintd.enable = true;

  system.stateVersion = "21.05"; # Version of NixOS first installed on this host

}

