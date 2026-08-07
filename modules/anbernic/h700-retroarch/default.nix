{ self }:
{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.anbernic.h700.retroarch;
  startRetroarch = pkgs.writeShellScript "anbernix-retroarch-session" ''
    set -eu

    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
    export EGL_PLATFORM=gbm

    mkdir -p \
      "$HOME/retroarch/saves" \
      "$HOME/retroarch/states" \
      "$HOME/retroarch/system" \
      "$HOME/retroarch/remaps" \
      "$HOME/retroarch/screenshots"

    for _ in 1 2 3 4 5 6 7 8 9 10; do
      [ -S "$XDG_RUNTIME_DIR/pipewire-0" ] && break
      sleep 1
    done

    ${pkgs.alsa-utils}/bin/amixer -D hw:0 cset numid=6 on,on >/dev/null 2>&1 || true
    exec ${lib.getExe cfg.package} --menu
  '';
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

    security.pam.services.anbernix-retroarch = lib.mkIf cfg.autostart {
      startSession = true;
    };

    systemd.services.anbernix-retroarch = lib.mkIf cfg.autostart {
      description = "Anbernix RetroArch session";
      after = [ "multi-user.target" "systemd-logind.service" "pipewire.service" ];
      wants = [ "systemd-logind.service" ];
      wantedBy = [ "multi-user.target" ];
      conflicts = [ "getty@tty1.service" "autovt@tty1.service" ];
      environment = {
        HOME = config.users.users.${cfg.user}.home;
        USER = cfg.user;
        XDG_SEAT = "seat0";
        XDG_VTNR = "1";
        EGL_PLATFORM = "gbm";
        XDG_SESSION_TYPE = "tty";
      };
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        SupplementaryGroups = [ "input" "video" "audio" "uinput" ];
        PAMName = "anbernix-retroarch";
        TTYPath = "/dev/tty1";
        TTYReset = true;
        TTYVHangup = true;
        StandardInput = "tty";
        StandardOutput = "tty";
        StandardError = "journal";
        UtmpIdentifier = "tty1";
        UtmpMode = "user";
        ExecStart = startRetroarch;
        ExecStopPost = "${pkgs.alsa-utils}/bin/amixer -D hw:0 cset numid=6 off,off";
        Restart = "always";
        RestartSec = "2s";
      };
    };
  };
}
