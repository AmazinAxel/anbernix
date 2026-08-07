{ self }:
{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.anbernic.h700.retroarch;
in {
  options.hardware.anbernic.h700.retroarch = {
    enable = lib.mkEnableOption "RetroArch configured for H700 Anbernic handhelds";

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to autologin on tty1 and start RetroArch.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "anbernix";
      description = "User account used for RetroArch autostart.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.retroarch-h700;
      defaultText = lib.literalExpression "anbernix.packages.<system>.retroarch-h700";
      description = "RetroArch package to install and launch.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    hardware.graphics.enable = lib.mkDefault true;
    security.rtkit.enable = lib.mkDefault true;

    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
    };

    users.users.${cfg.user} = lib.mkIf cfg.autostart {
      isNormalUser = true;
      extraGroups = [ "input" "video" "audio" "uinput" ];
    };

    services.getty.autologinUser = lib.mkIf cfg.autostart cfg.user;

    environment.loginShellInit = lib.mkIf cfg.autostart ''
      if [ "$(tty)" = /dev/tty1 ] && [ -z "$ANBERNIC_RETROARCH_STARTED" ]; then
        export ANBERNIC_RETROARCH_STARTED=1
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
        exec ${lib.getExe cfg.package} --menu
      fi
    '';
  };
}
