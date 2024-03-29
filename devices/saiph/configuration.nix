{ config, pkgs, ... }:

let
  release = "nixos-21.11";
  secrets = import ./secrets.nix;
in {
  imports = [
      ./hardware-configuration.nix
      ../../common
      ../../common/headless.nix
      ../../common/zfs.nix
      ../../users
      (builtins.fetchTarball {
        url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/${release}/nixos-mailserver-${release}.tar.gz";
        sha256 = "1i56llz037x416bw698v8j6arvv622qc0vsycd20lx3yx8n77n44";
      })
    ];

  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/vda";
    };
  };

  networking = {
    hostId = "7c848ede"; # Required for ZFS
    hostName = "saiph";
    domain = "packetize.me";
    useDHCP = false;
    interfaces.ens3.useDHCP = true;
  };

  networking.wireguard.enable = true;
  networking.wireguard.interfaces.wg0 = {
    ips = [ "172.27.1.6" ];
    listenPort = secrets.wg0.port;
    privateKeyFile = "/persist/secrets/wireguard/wg-saiph.key";
    peers = secrets.wg0.peers;
  };
  networking.hosts = {
    "172.27.1.7" = [ "mintaka" "mintaka.wg.local" ];
  };

  # Services
  services.nginx = {
    enable = true;
    virtualHosts."saiph.packetize.me" = {
      enableACME = true;
      forceSSL = true;
      root = "/persist/www/saiph.packetize.me";
    };
    virtualHosts."www.packetize.me" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = ''
        add_header Content-Security-Policy "frame-ancestors 'none'";
        add_header X-Frame-Options "DENY";
        add_header X-Content-Type-Options "nosniff";
        add_header Strict-Transport-Security "max-age=63072000" always;
        ssl_stapling on;
        ssl_stapling_verify on;
        resolver 127.0.0.1;
      '';
      root = "/persist/www/www.packetize.me";
    };
    virtualHosts."packetize.me" = {
      enableACME = true;
      forceSSL = true;
      root = "/persist/www/www.packetize.me";
      globalRedirect = "www.packetize.me";
    };
  };
  security.acme = {
    acceptTerms = true;
    certs = {
      "saiph.packetize.me" = {
        email = secrets.leah.email;
        postRun = ''
          cp fullchain.pem /persist/secrets/acme/saiph.packetize.me/
          cp full.pem /persist/secrets/acme/saiph.packetize.me/
          cp chain.pem /persist/secrets/acme/saiph.packetize.me/
          cp key.pem /persist/secrets/acme/saiph.packetize.me/
        '';
      };
      "www.packetize.me" = {
        email = secrets.leah.email;
        postRun = ''
          cp fullchain.pem /persist/secrets/acme/www.packetize.me/
          cp full.pem /persist/secrets/acme/www.packetize.me/
          cp chain.pem /persist/secrets/acme/www.packetize.me/
          cp key.pem /persist/secrets/acme/www.packetize.me/
        '';
      };
      "packetize.me" = {
        email = secrets.leah.email;
        postRun = ''
          cp fullchain.pem /persist/secrets/acme/packetize.me/
          cp full.pem /persist/secrets/acme/packetize.me/
          cp chain.pem /persist/secrets/acme/packetize.me/
          cp key.pem /persist/secrets/acme/packetize.me/
        '';
      };
    };
  };
  mailserver = {
    enable = true;
    fqdn = "saiph.packetize.me";
    mailDirectory = "/persist/mail/vmail";
    domains = secrets.postfix.relayDomains;
    loginAccounts = secrets.mailserver.loginAccounts;
    forwards = secrets.mailserver.forwards;
    certificateScheme = 1;
    certificateFile = "/persist/secrets/acme/saiph.packetize.me/fullchain.pem";
    keyFile = "/persist/secrets/acme/saiph.packetize.me/key.pem";
    dkimKeyDirectory = "/persist/mail/dkim";
    dkimSelector = "saiph";
    lmtpSaveToDetailMailbox = "no";
    hierarchySeparator = "/";
    fullTextSearch.enable = true;
  };
  services.rspamd.overrides = {
    "actions.conf".text = ''
      greylist = 10;
      reject = null;
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ secrets.wg0.port ];

  # Automatic backup
  services.borgbackup.jobs.home = secrets.services.borgbackup.jobs.home;
  services.borgbackup.jobs.persist = secrets.services.borgbackup.jobs.persist;

  # Version of NixOS initially installed
  system.stateVersion = "20.09";

}

