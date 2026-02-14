{ lib, ... }:
{
  services.open-vm-tools.enable = true;

  # Keep VMware guest support explicit for installer and installed guests.
  virtualisation.vmware.guest.enable = true;

  # Prefer VMware virtual hardware drivers at early boot for stable bring-up.
  boot.initrd.availableKernelModules = lib.mkBefore [
    "vmw_pvscsi"
    "vmxnet3"
  ];
}
