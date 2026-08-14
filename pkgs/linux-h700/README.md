# Kernel Sources

The H700 kernel package reads its config, patches and panel firmware from the
locked `rocknix` flake input — nothing is vendored here:

```text
ROCKNIX/distribution
projects/ROCKNIX/devices/H700/linux/linux.aarch64.conf
projects/ROCKNIX/devices/H700/patches/linux
projects/ROCKNIX/packages/linux/patches/7.0
projects/ROCKNIX/packages/linux/patches/mainline
projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware
```

`nix flake update rocknix` is normally all that a ROCKNIX kernel bump needs.

## Config

`default.nix` takes ROCKNIX's config verbatim and applies `configOverlay` on
top. That overlay is deliberately small:

- the two `@PLACEHOLDER@` values ROCKNIX's own build system substitutes
  (`INITRAMFS_SOURCE`, `DEFAULT_HOSTNAME`)
- `EXTRA_FIRMWARE`, generated from the `builtinFirmware` attrset so the config
  and the blobs staged in `postPatch` cannot drift apart
- the options systemd requires under NixOS (`nixos/modules/system/boot/systemd.nix`,
  `system.requiredKernelConfig`). ROCKNIX already sets all of these, so today
  the overlay is a no-op guard rather than a change.

`DMIID` is the one required option we cannot set — it is x86-only. It is faked
in `passthru.config` instead (`armMissingOptions`).

Three things fail the build rather than degrading silently:

- a config placeholder the overlay does not substitute
- a ROCKNIX H700 kernel version bump, which needs a new source tarball hash and
  a fresh look at the patch set
- an overlay option that does not survive `make oldconfig`, which would
  otherwise leave NixOS asserting against options the kernel does not have
