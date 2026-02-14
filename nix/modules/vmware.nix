{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.open-vm-tools];

  # Keep VMware guest support explicit for installer and installed guests.
  virtualisation.vmware.guest.enable = true;

  # Prefer VMware virtual hardware drivers at early boot for stable bring-up.
  boot.initrd.availableKernelModules = lib.mkBefore [
    "vmw_pvscsi"
    "vmxnet3"
  ];
}
