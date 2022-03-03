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

  networking.wireguard.enable = true;
  networking.wireguard.interfaces.wg0 = {
    ips = [ "172.27.1.7" ];
    listenPort = secrets.wg0.port;
    privateKeyFile = "/persist/secrets/wireguard/wg-mintaka.key";
    peers = secrets.wg0.peers;
  };
  networking.hosts = {
    "172.27.1.6" = [ "saiph" "saiph.wg.local" ];
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
      };
    };
  };
  services.postfix = {
    enable = true;
    hostname = "mintaka.packetize.me";
    relayDomains = secrets.postfix.relayDomains;
    relayHost = "saiph.packetize.me";
    sslCert = "/var/lib/acme/mintaka.packetize.me/fullchain.pem";
    sslKey = "/var/lib/acme/mintaka.packetize.me/key.pem";
  };

  networking.firewall.allowedTCPPorts = [ 25 80 443 ];
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ secrets.wg0.port ];

  system.stateVersion = "21.05"; # Did you read the comment?

}

