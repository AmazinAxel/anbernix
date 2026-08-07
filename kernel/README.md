# Kernel Sources

The H700 kernel package reads ROCKNIX-derived patches and panel firmware from
the locked `rocknix` flake input:

```text
ROCKNIX/distribution
projects/ROCKNIX/devices/H700/patches/linux
projects/ROCKNIX/packages/linux/patches/mainline
projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware
```

Local files here are intentional deltas:

- `rocknix-linux.conf`: kernel config currently used by the NixOS build.
- `local-patches/0001-gpiolib-of-revert-api-changes-needed-for-joypad-driver.patch`:
  local or older ROCKNIX patch not present in current ROCKNIX `next`.

The force-feedback patch is still enabled for Anbernix, but its contents are
read directly from ROCKNIX's `0150-add-forcefeedback.patch.disabled`.
