{ config, pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{
  imports = [
      ./hardware-configuration.nix
      ../../common
      ../../common/headless.nix
      ../../common/zfs.nix
      ../../users
    ];

  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sdb";
    };
  };

  networking = {
    hostId = "081b6776"; # Required for ZFS
    hostName = "mintaka";
    domain = "packetize.me";
    useDHCP = false;
    interfaces.enp0s5.useDHCP = true;
  };

  # Services
  services.nginx = {
    enable = true;
    virtualHosts."mintaka.packetize.me" = {
      enableACME = true;
      forceSSL = true;
      root = "/persist/www/mintaka.packetize.me";
    };
  };
  security.acme = {
    acceptTerms = true;
    certs = {
      "mintaka.packetize.me" = {
        email = secrets.leah.email;
        postRun = ''
          cp fullchain.pem "/persist/secrets/acme/mintaka.packetize.me/"
          cp full.pem "/persist/secrets/acme/mintaka.packetize.me/"
          cp chain.pem "/persist/secrets/acme/mintaka.packetize.me/"
          cp key.pem "/persist/secrets/acme/mintaka.packetize.me/"
        '';
      };
    };
  };
  services.postfix = {
    enable = true;
    hostname = "mintaka.packetize.me";
    relayDomains = secrets.postfix.relayDomains;
    relayHost = "saiph.packetize.me";
    sslCert = "/persist/secrets/acme/mintaka.packetize.me/fullchain.pem";
    sslKey = "/persist/secrets/acme/mintaka.packetize.me/key.pem";
  };

  networking.firewall.allowedTCPPorts = [ 22 25 80 443 ];

  system.stateVersion = "21.05"; # Did you read the comment?

}

