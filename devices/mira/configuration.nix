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
    networkmanager.enable = true;
    wireless.enable = false; # we're using network manager and wpa_supplicant delays boot significantly
                             # edit - turns out this doesn't make a difference, because network-manager
                             # uses wpa_supplicant under the hood. An alternative exists but is labeled
                             # experimental; I'll try it out later.
    useDHCP = false;
    # Disabled interface-specific useDHCP because it delays boot significantly
    # This is addressed by network manager without setting things here.
    interfaces.enp133s0.useDHCP = false;
    interfaces.wlp170s0.useDHCP = false;

    # Need to figure out why boot is so slow and how to improve it. Appears to be related to bringing wifi interface up.
    # ```
    # [leah@mira:~/code/nixos-config/devices/mira]$ sudo systemd-analyze critical-chain
    # The time when unit became active or started is printed after the "@" character.
    # The time the unit took to start is printed after the "+" character.
    #
    # graphical.target @1min 30.495s
    # └─display-manager.service @1min 30.424s +68ms
    #   └─systemd-user-sessions.service @1min 30.416s +7ms
    #     └─network.target @1min 30.411s
    #       └─network-local-commands.service @1min 30.406s +5ms
    #         └─network-setup.service @1min 30.302s +102ms
    #           └─network-addresses-wlp170s0.service @1.230s +280ms
    #             └─sys-subsystem-net-devices-wlp170s0.device @1.229s
    # ```
    # Tried marking the wifi interface as unmanaged, which got rid of the boot delay, but left me with no wifi.
    # networkmanager = {
    #   enable = true;
    #   unmanaged = [ "wlp170s0" ];
    # };
    #
    # ```
    # [leah@mira:~]$ sudo systemd-analyze critical-chain
    # The time when unit became active or started is printed after the "@" character.
    # The time the unit took to start is printed after the "+" character.
    #
    # graphical.target @889ms
    # └─accounts-daemon.service @702ms +186ms
    #   └─nss-user-lookup.target @701ms
    #     └─nscd.service @680ms +20ms
    #       └─basic.target @674ms
    #         └─sockets.target @674ms
    #           └─nix-daemon.socket @674ms
    #             └─sysinit.target @672ms
    #               └─swap.target @672ms
    #                 └─dev-mapper-cryptswap.swap @667ms +5ms
    #                   └─dev-mapper-cryptswap.device @666ms # Nice. (except not really, it'd be cool if this were faster :))
    # ```
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

