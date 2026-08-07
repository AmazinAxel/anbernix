# Kernel Sources

The H700 kernel package reads ROCKNIX-derived patches and panel firmware from
the locked `rocknix` flake input:

```text
ROCKNIX/distribution
projects/ROCKNIX/devices/H700/patches/linux
projects/ROCKNIX/packages/linux/patches/7.0
projects/ROCKNIX/packages/linux/patches/mainline
projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware
```

Local files here are intentional deltas:

- `rocknix-linux.conf`: kernel config currently used by the NixOS build.
