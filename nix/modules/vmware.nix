{ lib, ... }:
{
  # Keep VMware guest support explicit for both installer ISO and VMDK outputs.
  virtualisation.vmware.guest.enable = true;

  # Prefer VMware virtual hardware drivers at early boot for stable bring-up.
  boot.initrd.availableKernelModules = lib.mkBefore [
    "vmw_pvscsi"
    "vmxnet3"
  ];
}
