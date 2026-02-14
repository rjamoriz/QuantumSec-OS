{ lib, modulesPath, pkgs, self, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ../modules/base.nix
    ../modules/security.nix
    ../modules/vmware.nix
    ../modules/quantum.nix
  ];

  networking.hostName = "quantumsec-iso";
  networking.wireless.enable = lib.mkForce false;

  # Keep the installer image directly usable in VMware Fusion with UEFI.
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "quantumsec-install-guide" ''
      cat <<'EOF'
QuantumSec OS install quick guide (persistent VM disk):

  1) Partition target disk (example /dev/sda), then:
       mkfs.ext4 /dev/sda1
       mount /dev/sda1 /mnt
       mkdir -p /mnt/boot

  2) Generate hardware config:
       nixos-generate-config --root /mnt

  3) Install the persistent QuantumSec VM profile:
       nixos-install --root /mnt --flake ${self}#quantumsec-vmware

  4) Reboot into installed system and log in as:
       user: quantum
       pass: quantum   (change immediately)
EOF
    '')
  ];
}
