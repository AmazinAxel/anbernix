{ pkgs
, lib
, rocknix
, ...
}:

let
  rocknixH700 = rocknix + "/projects/ROCKNIX/devices/H700";
  rocknixLinuxPkg = rocknix + "/projects/ROCKNIX/packages/linux";
  rocknixKernelPatches = rocknixLinuxPkg + "/patches";
  rocknixMainline = rocknixKernelPatches + "/mainline";
  rocknixFirmware = rocknix + "/projects/ROCKNIX/packages/linux-firmware/kernel-firmware/extra-firmware";

  patchNames = dir:
    builtins.filter (f: lib.hasSuffix ".patch" f)
      (builtins.attrNames (builtins.readDir dir));

  patchesFrom = dir: map (p: dir + "/${p}") (patchNames dir);

  # ROCKNIX starts H700 with PKG_PATCH_DIRS="linux mainline H700 default".
  # Its build system applies dirs in that order, each dir's patches sorted by
  # filename. The "linux" and "default" dirs only exist under the top-level
  # packages/linux, which the project-level projects/ROCKNIX/packages/linux
  # shadows entirely, so what is left is mainline, the device dir, then the
  # kernel-version patch dir that ROCKNIX's linux package automatically adds.
  # Keep that order: it is what ROCKNIX actually validates.
  mainlinePatches = patchesFrom rocknixMainline;
  # Hardcoded from ROCKNIX projects/ROCKNIX/packages/linux/package.mk: Linux
  # 7.2 automatically adds the matching patches/7.2 dir.
  seriesPatches = patchesFrom (rocknixKernelPatches + "/7.2");

  h700PatchDir = rocknixH700 + "/patches/linux";
  # Sort by basename to match ROCKNIX's patch application order.
  devicePatches =
    lib.sortOn builtins.baseNameOf
      (patchesFrom h700PatchDir);

  orderedPatches = mainlinePatches ++ devicePatches ++ seriesPatches;

  armMissingOptions = [ "DMIID" ];

  # Firmware built into the kernel image for working wifi, bluetooth and
  # display. Keys are paths under CONFIG_EXTRA_FIRMWARE_DIR; the same attrset
  # stages the files and generates CONFIG_EXTRA_FIRMWARE so the two can't drift.
  builtinFirmware = {
    "rtl_bt/rtl8821cs_config.bin" = "${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8821cs_config.bin";
    "rtl_bt/rtl8821cs_fw.bin" = "${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8821cs_fw.bin";
    "rtw88/rtw8821c_fw.bin" = "${pkgs.linux-firmware}/lib/firmware/rtw88/rtw8821c_fw.bin";
    # Panel blobs come from ROCKNIX so they update with the locked input.
    "panels/anbernic,rg35xx-plus-panel.panel" = "${rocknixFirmware}/panels/anbernic,rg35xx-plus-panel.panel";
    "panels/anbernic,rg35xx-plus-rev6-panel.panel" = "${rocknixFirmware}/panels/anbernic,rg35xx-plus-rev6-panel.panel";
  };

  # ROCKNIX's own linux package builds Linux ${rocknixLinuxVersion} for H700,
  # parsed out of the `case ${DEVICE}` block in its package.mk. We use it to
  # catch the source pin drifting away from the ROCKNIX input.
  packageMkLines = lib.splitString "\n" (builtins.readFile (rocknixLinuxPkg + "/package.mk"));
  h700Case = lib.findFirst (x: builtins.match " *.*H700.*\\)" x.line != null) null
    (lib.imap0 (index: line: { inherit index line; }) packageMkLines);
  rocknixLinuxVersion =
    let
      match = lib.findFirst (m: m != null) null
        (map (l: builtins.match " *PKG_VERSION=\"([^\"]+)\"" l)
          (lib.drop h700Case.index packageMkLines));
    in
    if h700Case == null then null
    else if match == null then null
    else lib.head match;

  # Pinned directly from kernel.org to match ROCKNIX's H700 PKG_VERSION.
  kernelVersion = "7.2";
  kernelHash = "sha256-+f7z0UwN9TgZAm9L50RZg1wqCw3L9bW72eoZ8IKUArM=";

  series = v: lib.concatStringsSep "." (lib.take 2 (lib.splitString "." v));

  # ROCKNIX resolves the config with the search order in config/functions
  # (kernel_config_path). Only the last entry exists for H700 today, but follow
  # the same order so a future per-version config is picked up automatically.
  configCandidates =
    lib.optionals (rocknixLinuxVersion != null) [
      (rocknixH700 + "/linux/${rocknixLinuxVersion}/linux.aarch64.conf")
      (rocknixH700 + "/linux/${series rocknixLinuxVersion}/linux.aarch64.conf")
    ]
    ++ [ (rocknixH700 + "/linux/linux.aarch64.conf") ];
  rocknixConfigFile = lib.findFirst builtins.pathExists null configCandidates;

  # Options ROCKNIX's build system substitutes at build time (its config ships
  # @PLACEHOLDER@ values), plus the ones NixOS needs. Everything else is taken
  # verbatim from ROCKNIX. As of the current input the systemd-required set is
  # already satisfied upstream, so listing it here is a guard, not a change:
  # if ROCKNIX ever drops one we turn it back on and the postConfigure check
  # fails the build if the dependencies to do so aren't there.
  #
  # DMIID is deliberately absent: it is x86-only and unsatisfiable on arm64.
  # It is faked in passthru.config instead (see armMissingOptions).
  configOverlay = {
    # ROCKNIX points this at its own initramfs; NixOS builds its own.
    INITRAMFS_SOURCE = ''""'';
    # ROCKNIX substitutes @DEVICENAME@; NixOS sets the hostname from config.
    DEFAULT_HOSTNAME = ''"nixos"'';
    EXTRA_FIRMWARE = ''"${lib.concatStringsSep " " (lib.attrNames builtinFirmware)}"'';
    EXTRA_FIRMWARE_DIR = ''"external-firmware"'';
  } // lib.genAttrs [
    "DEVTMPFS"
    "CGROUPS"
    "INOTIFY_USER"
    "SIGNALFD"
    "TIMERFD"
    "EPOLL"
    "NET"
    "SYSFS"
    "PROC_FS"
    "FHANDLE"
    "CRYPTO_USER_API_HASH"
    "CRYPTO_HMAC"
    "CRYPTO_SHA256"
    "BT_LE"
    "HIDRAW"
    "UHID"
    "AUTOFS_FS"
    "TMPFS_POSIX_ACL"
    "TMPFS_XATTR"
    "SECCOMP"
  ] (_: "y");

  overlayLines = lib.mapAttrsToList (name: value: "CONFIG_${name}=${value}") configOverlay;

  # Drop any existing definition of an overridden symbol before appending ours:
  # nixpkgs' readConfig uses listToAttrs, which keeps the *first* occurrence, so
  # a duplicate line would silently win over the overlay.
  overriddenBy = line:
    lib.any
      (name: line == "# CONFIG_${name} is not set" || lib.hasPrefix "CONFIG_${name}=" line)
      (lib.attrNames configOverlay);

  configText = lib.concatStringsSep "\n" (
    lib.filter (l: !(overriddenBy l))
      (lib.splitString "\n" (builtins.readFile rocknixConfigFile))
    ++ overlayLines
    ++ [ "" ]
  );

  # ROCKNIX's config carries @PLACEHOLDER@ values that its build system fills
  # in. We handle the ones that exist today via configOverlay; a new one would
  # otherwise be baked into the kernel literally.
  leftoverPlaceholders = lib.filter
    (l: builtins.match "[^#].*@[A-Z_]+@.*" l != null)
    (lib.splitString "\n" configText);

  configFile = builtins.toFile "linux-h700.config" configText;
  parsedConfig =
    let
      matchLine = line:
        let
          match = builtins.match "(CONFIG_[^=]+)=([ym])" line;
        in
        lib.optional (match != null) {
          name = lib.elemAt match 0;
          value = lib.elemAt match 1;
        };
    in
    lib.listToAttrs (lib.concatMap matchLine (lib.splitString "\n" configText));

  baseKernel = pkgs.linuxManualConfig {
    version = kernelVersion;
    modDirVersion = kernelVersion;
    src = pkgs.fetchurl {
      url = "mirror://kernel/linux/kernel/v7.x/linux-${kernelVersion}.tar.xz";
      hash = kernelHash;
    };
    configfile = configFile;
    config = parsedConfig;
    kernelPatches = map (p: {
      name = builtins.baseNameOf p;
      patch = p;
    }) orderedPatches;
    allowImportFromDerivation = true;
  };

  kernel = baseKernel.overrideAttrs (old: {
    passthru = old.passthru // {
      inherit rocknixConfigFile rocknixLinuxVersion configOverlay;

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
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (dest: src: ''
        install -Dm444 ${lib.escapeShellArg src} ${lib.escapeShellArg "external-firmware/${dest}"}
      '') builtinFirmware)}
    '';

    # `make oldconfig` silently drops symbols whose dependencies aren't met, and
    # the config NixOS asserts against is the *input* file rather than the
    # reconciled one. Fail here instead of shipping a kernel that quietly lost
    # something the overlay asked for.
    postConfigure = (old.postConfigure or "") + ''
      dropped=()
      while IFS= read -r expected; do
        [ -n "$expected" ] || continue
        grep -qxF "$expected" "$buildRoot/.config" || dropped+=("$expected")
      done <<< ${lib.escapeShellArg (lib.concatStringsSep "\n" overlayLines)}

      if [ ''${#dropped[@]} -gt 0 ]; then
        echo "error: kernel config overlay did not survive 'make oldconfig':" >&2
        printf '  %s\n' "''${dropped[@]}" >&2
        exit 1
      fi
    '';
  });
in
lib.throwIf (rocknixLinuxVersion == null)
  "could not parse the H700 PKG_VERSION out of ${toString rocknixLinuxPkg}/package.mk"
  (lib.throwIf (rocknixConfigFile == null)
    ("no ROCKNIX H700 kernel config found; looked for:\n"
      + lib.concatMapStringsSep "\n" (c: "  ${toString c}") configCandidates)
    (lib.throwIf (rocknixLinuxVersion != kernelVersion)
      ("ROCKNIX now builds Linux ${rocknixLinuxVersion} for H700, but pkgs/linux-h700 "
        + "pins ${kernelVersion}. Bump kernelVersion and kernelHash, then re-check "
        + "the patch set in ${toString rocknixKernelPatches}.")
      (lib.throwIf (leftoverPlaceholders != [ ])
        ("ROCKNIX's kernel config has build-system placeholders that configOverlay "
          + "does not substitute:\n"
          + lib.concatMapStringsSep "\n" (l: "  ${l}") leftoverPlaceholders)
        kernel)))
