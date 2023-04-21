{ config, pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../common
      ../../common/gui.nix
      ../../common/zfs.nix # Excluded until autoscrub is moved to headless
      ../../users
      ../../users/home-manager.nix
      ./modules/murmur.nix
      #<nixpkgs/nixos/modules/profiles/hardened.nix>
    ];

  nixpkgs.overlays =
    [
      (import ./overlays/uhd.nix)
      (import ./overlays/urh.nix)
      (import ./overlays/murmur.nix)
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.config.allowUnfree = true;

  # Nix features
  # Add remote build machine
  nix.buildMachines = [{
    hostName = "datass";
    sshUser = "builduser";
    systems = [ "x86_64-linux" "i686-linux" ];
    maxJobs = 16;
    speedFactor = 8;
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    mandatoryFeatures = [ ];
  }];
  #nix.distributedBuilds = true;

  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
    builders-use-substitutes = true # Speeds things up by downloading dependencies remotely:
    experimental-features = nix-command flakes
  '';

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

    wireguard.interfaces.wg0 = secrets.wg0;

    hosts = secrets.hosts;

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


  # services.udev.packages = with pkgs; [ uhd ];

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager = {
      sddm.enable = true; # LightDM is default and was not playing nice with plasma-wayland. SDDM looks better anyhow.
      defaultSession = "plasmawayland";
    };
    desktopManager.plasma5.enable = true;
    desktopManager.plasma5 = {
      useQtScaling = true;
    };
    # xkbOptions = "ctrl:swapcaps"; # Disabled because my fingers were getting confused. Can we just disable caps and use both keys for ctrl?
  };

  security.pam.services.KWallet.enableKwallet = true; # Don't ask us to auth to kwallet at login - this isn't set by plasma5.enable.
  security.pam.services.login.enableKwallet = true;
  security.tpm2.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu.runAsRoot = false;
  };
  environment.systemPackages = with pkgs; [
    libsForQt5.bismuth
    bind # Provides nslookup, dig
    czkawka
    direnv
    emacs
    file
    git
    htop
    isync
    jq
    jless
    lutris
    mosh
    niv
    nmap
    notmuch
    p7zip
    ripgrep
    shellcheck
    sqlite
    tcpdump
    #tor-browser-bundle-bin
    tree
    lorri
    virt-manager
    vulkan-tools
    wget
    whois
    # Radio packages
    # uhd # USRP
    # gnuradio
    # gqrx # simple SDR
    # urh
    # gnss-sdr # GNSS receiver
    #chirp
    #alacritty
    weechat
    #poetry
    wmctrl # needed so we can activate windows from cli
    libreoffice-qt
    hunspell
    makemkv
    nushell
    starship
    zellij # tmux alternative? added to check it out, not convinced tmux needs replacing
    kitty
    remmina
    ksshaskpass
    fishPlugins.tide
    fishPlugins.fzf-fish # Requires fzf, fd
    fzf
    fd
  ];

  programs.steam.enable = true;
  programs.firefox.enable = true;
  programs.fish.enable = true;
  programs.iotop.enable = true;
  #programs.starship.enable = true;
  programs.command-not-found.enable = false;

  # Some hardening options
  security.apparmor.enable = true;
  services.dbus.apparmor = "enabled";
  security.apparmor.killUnconfinedConfinables = true;
  systemd.coredump.enable = false; # Not like I'm going to dig through these anyhow.
  security.forcePageTableIsolation = true;

  ## BEGIN HARDENED CONFIG
  # Restrict ptrace() usage to processes with a pre-defined relationship
  # (e.g., parent/child)
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = 1;

  # Hide kptrs even for processes with CAP_SYSLOG
  boot.kernel.sysctl."kernel.kptr_restrict" = 2;

  # Disable bpf() JIT (to eliminate spray attacks)
  boot.kernel.sysctl."net.core.bpf_jit_enable" = false;

  # Disable ftrace debugging
  #boot.kernel.sysctl."kernel.ftrace_enabled" = false;

  # Enable strict reverse path filtering (that is, do not attempt to route
  # packets that "obviously" do not belong to the iface's network; dropped
  # packets are logged as martians).
  boot.kernel.sysctl."net.ipv4.conf.all.log_martians" = true;
  boot.kernel.sysctl."net.ipv4.conf.all.rp_filter" = "1";
  boot.kernel.sysctl."net.ipv4.conf.default.log_martians" = true;
  boot.kernel.sysctl."net.ipv4.conf.default.rp_filter" = "1";

  # Ignore broadcast ICMP (mitigate SMURF)
  boot.kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = true;

  # Ignore incoming ICMP redirects (note: default is needed to ensure that the
  # setting is applied to interfaces added after the sysctls are set)
  boot.kernel.sysctl."net.ipv4.conf.all.accept_redirects" = false;
  boot.kernel.sysctl."net.ipv4.conf.all.secure_redirects" = false;
  boot.kernel.sysctl."net.ipv4.conf.default.accept_redirects" = false;
  boot.kernel.sysctl."net.ipv4.conf.default.secure_redirects" = false;
  boot.kernel.sysctl."net.ipv6.conf.all.accept_redirects" = false;
  boot.kernel.sysctl."net.ipv6.conf.default.accept_redirects" = false;

  # Ignore outgoing ICMP redirects (this is ipv4 only)
  boot.kernel.sysctl."net.ipv4.conf.all.send_redirects" = false;
  boot.kernel.sysctl."net.ipv4.conf.default.send_redirects" = false;
  ## END HARDENED PROFILE

  # services.opensnitch.enable = true;
  programs.firejail.enable = true;
  programs.firejail.wrappedBinaries = {
    # Programs to run in firejail by default
    #firefox = {
    #  executable = "${pkgs.lib.getBin pkgs.firefox}/bin/firefox";
    #  profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
    #  extraArgs = [
    #    "--apparmor"
    #  ];
    #};
  };
  # security.chromium.SuidSandbox.enable = true; # Run chromium in a sandbox

  # gnome3 and KDE cannot coexist without some nudging
  # force use of a specific askPassword program or Nix will barf
  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";
  # The above (^) barfed too. Let's try disabling one of the sources of conflict.
  programs.seahorse.enable = false;
  programs.ssh.startAgent = true;

  # Enable sound.
  sound.enable = true;
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
    };
  };

  # Vulkan
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  # services.touchegg.enable = true;

  #users.users.root.hashedPassword = secrets.root.hashedPassword;
  #users.users.leah.hashedPassword = secrets.leah.hashedPassword;

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

  services.lorri.enable = false;
  # Local jupyter
  # services.jupyter.enable = true;

  # pgsql for local Phoenix development
  services.pgadmin = {
    enable = true;
    initialEmail = secrets.leah.email;
    initialPasswordFile = "/persist/secrets/postgresql/pgadmin.initialpw";
  };
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hello_dev" ];
    ensureUsers = [
      {
        name = "leah";
        ensurePermissions = {
          "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
        };
      }
      {
        name = "phoenix";
        ensurePermissions = {
          "DATABASE hello_dev" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.murmur.enable = false;

  services.tailscale.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  networking.extraHosts = ''
  '';

  # Verified that bluetooth is working this version
  #boot.kernelPackages = pkgs.linuxPackages_5_15;

  #boot.kernelPackages = pkgs.linuxPackages_hardened;
  #services.fprintd.enable = true;

  # Improve power usage?
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;
  services.tlp.settings = {
    PCIE_ASPM_ON_BAT = "powersupersave";
  };

  # Allow deep sleep
  boot.kernelParams = [
    "mem_sleep_default=deep"
  ];

  # Font stuff
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      ubuntu_font_family
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      source-code-pro
      nerdfonts
      #(nerdfonts.override { fonts = ["SourceCodePro"]; })
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "Ubuntu" ];
        sansSerif = [ "Ubuntu" ];
        monospace = [ "Ubuntu" ];
      };
    };
  };

  assertions = [
    {
      assertion = config.hardware.cpu.amd.updateMicrocode || config.hardware.cpu.intel.updateMicrocode || pkgs.system != "x86_64-linux";
      message = "updateMicrocode should be set for intel or amd";
    }
  ];

  system.stateVersion = "21.05"; # Version of NixOS first installed on this host

}

