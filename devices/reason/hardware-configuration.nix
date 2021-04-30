# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices = {
    cryptdev0.device = "/dev/disk/by-uuid/e8ecbebd-2ce5-435f-8aca-192a70acc013";
  };

  fileSystems."/" =
    { device = "tank0/local/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8F45-53B4";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "tank0/safe/home";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    { device = "tank0/safe/persist";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "tank0/local/nix";
      fsType = "zfs";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
