{ config, pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../common
      ../../common/headless.nix
      ../../common/zfs.nix
      ../../users
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  networking.hostId = "4d6c68bf";
  networking.hostName = "moom";
  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  users.groups = { tripwire = { }; };
  users.users.tripwire = {
    isSystemUser = true;
    group = "tripwire";
    home = "/opt/tripwire";
    description = "Tripwire Service";
    packages = [ pkgs.php ];
  };

  services.mysql = {
    enable = true;
    bind = "localhost";
    ensureDatabases = [ "tripwire" "evetq_20201208" ];
    ensureUsers = [
      {
        name = "tripwire";
        ensurePermissions = {
          "tripwire.*" = "ALL PRIVILEGES";
          "evetq_20201208.*" = "SELECT, LOCK TABLES";
        };
      }
    ];
    settings = {
      mysqld = {
        event_scheduler = "on";
        sql_mode="NO_ENGINE_SUBSTITUTION";
      };
    };
    package = pkgs.mysql;
  };
  services.phpfpm = {
    pools = {
      tripwire = {
        user = "tripwire";
        group = "tripwire";
        phpPackage = pkgs.php;
        settings = {
          "listen.owner" = config.services.nginx.user;
          "pm" = "dynamic";
          "pm.max_children" = 75;
          "pm.start_servers" = 10;
          "pm.min_spare_servers" = 5;
          "pm.max_spare_servers" = 20;
          "pm.max_requests" = 500;
          "php_admin_value[error_log]" = "/var/log/tripwire-php.log";
          "php_admin_value[log_level]" = "debug";
          "php_admin_flag[log_errors]" = true;
          "catch_workers_output" = true;
        };
      };
    };
  };
  security.acme.email = secrets.leah.email;
  security.acme.acceptTerms = true;
  services.nginx = {
    enable = true;
    enableReload = true;
    virtualHosts = {
      "tripwire.packetize.me" = {
        enableACME = true;
        forceSSL = true;
        root = "/opt/tripwire/tripwire/public";
        locations = {
          "/" = {
            index = "index.php index.html";
          };
          "/api".extraConfig = ''
            rewrite ^/api(.*) api.php?q=$1;
          '';
          "~ \.php$".extraConfig = ''
            try_files $uri =404;
            fastcgi_pass unix:/run/phpfpm/tripwire.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include ${pkgs.nginx}/conf/fastcgi_params;
            include ${pkgs.nginx}/conf/fastcgi.conf;
          '';
        };
      };
    };
  };
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 * * * * tripwire /etc/profiles/per-user/tripwire/bin/php /opt/tripwire/tripwire/system_activity.cron.php"
      "*/3 * * * * tripwire /etc/profiles/per-user/tripwire/bin/php /opt/tripwire/tripwire/account_update.cron.php"
    ];
  };

  system.stateVersion = "20.03"; # Did you read the comment?

}

