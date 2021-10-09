{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_scsi" "ahci" "sd_mod" "virtio_net" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices = {
    cryptdev0.device = "/dev/disk/by-uuid/9f0f6936-f8d5-4242-9ce4-efe983330046";
    cryptswap.device = "/dev/disk/by-uuid/4828dafb-e944-447e-b97e-30eb58d0c618";
  };

  fileSystems."/" =
    { device = "tank0/local/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/4844ed03-dbc2-4c41-84a6-07d4b058e5d2";
      fsType = "ext4";
    };

  fileSystems."/nix" =
    { device = "tank0/local/nix";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "tank0/safe/home";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    { device = "tank0/safe/persist";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/mapper/cryptswap"; }
    ];

}
