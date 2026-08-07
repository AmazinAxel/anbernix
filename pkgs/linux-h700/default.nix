{ pkgs
, lib
, rocknix
, ...
}:

let
  rocknixH700 = rocknix + "/projects/ROCKNIX/devices/H700";
  rocknixMainline = rocknix + "/projects/ROCKNIX/packages/linux/patches/mainline";
  rocknixFirmware = rocknix + "/projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware";

  patchNames = dir:
    builtins.filter (f: lib.hasSuffix ".patch" f)
      (builtins.attrNames (builtins.readDir dir));

  patchesFrom = dir: map (p: dir + "/${p}") (patchNames dir);

  mainlinePatches = [
    ../../kernel/local-patches/0001-gpiolib-of-revert-api-changes-needed-for-joypad-driv.patch
    (rocknixMainline + "/0002-input-add-input-polldev-driver.patch")
    (rocknixMainline + "/0003-pwm-add-pwm_set_period.patch")
    (rocknixMainline + "/0004-input-adc-keys-redirect-keycode-316-to-rocknix-joypa.patch")
  ];

  h700PatchDir = rocknixH700 + "/patches/linux";
  devicePatches = patchesFrom h700PatchDir ++ [
    # ROCKNIX ships this disabled, but the current Anbernix host had it enabled.
    (h700PatchDir + "/0150-add-forcefeedback.patch.disabled")
  ];

  armMissingOptions = [ "DMIID" ];

  # Extra firmware for working wifi and display. The panel blobs are sourced
  # from ROCKNIX so they update with the locked ROCKNIX input.
  extraFirmwareFiles = pkgs.runCommand "kernel-extra-firmware" {} ''
    mkdir -p $out/rtl_bt $out/rtw88 $out/panels
    cp ${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8821cs_config.bin $out/rtl_bt/
    cp ${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8821cs_fw.bin $out/rtl_bt/
    cp ${pkgs.linux-firmware}/lib/firmware/rtw88/rtw8821c_fw.bin $out/rtw88/
    cp ${rocknixFirmware}/panels/anbernic,rg35xx-plus-panel.panel $out/panels/
    cp ${rocknixFirmware}/panels/anbernic,rg35xx-plus-rev6-panel.panel $out/panels/
  '';

  # Pinned directly from kernel.org: nixpkgs dropped linux_7_0 at its upstream
  # EOL, but the ROCKNIX patch set + config are validated against 7.0.y.
  # 7.0.14 is the final 7.0.y release.
  kernelVersion = "7.0.14";

  baseKernel = pkgs.linuxManualConfig {
    version = kernelVersion;
    modDirVersion = kernelVersion;
    src = pkgs.fetchurl {
      url = "mirror://kernel/linux/kernel/v7.x/linux-${kernelVersion}.tar.xz";
      hash = "sha256-3pmZt4TSKT8A05xi2PkqCKuKVLxOgP/SUKDAnLB6D5g=";
    };
    configfile = ../../kernel/rocknix-linux.conf;
    kernelPatches = map (p: {
      name = builtins.baseNameOf p;
      patch = p;
    }) (mainlinePatches ++ devicePatches);
    allowImportFromDerivation = true;
  };
in
baseKernel.overrideAttrs (old: {
  passthru = old.passthru // {
    config = old.passthru.config // {
      isEnabled = opt:
        if builtins.elem opt armMissingOptions then true
        else old.passthru.config.isEnabled opt;
      isYes = opt:
        if builtins.elem opt armMissingOptions then true
        else old.passthru.config.isYes opt;
      isSet = opt:
        if builtins.elem opt armMissingOptions then true
        else old.passthru.config.isSet opt;
    };
  };

  postPatch = (old.postPatch or "") + ''
    mkdir -p external-firmware/rtl_bt external-firmware/rtw88 external-firmware/panels
    cp ${extraFirmwareFiles}/rtl_bt/* external-firmware/rtl_bt/
    cp ${extraFirmwareFiles}/rtw88/* external-firmware/rtw88/
    cp ${extraFirmwareFiles}/panels/* external-firmware/panels/
  '';
})
