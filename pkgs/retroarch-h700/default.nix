{ dbus
, lib
, libretro
, libretro-core-info
, makeBinaryWrapper
, retroarch-assets
, retroarch-bare
, retroarch-joypad-autoconfig
, symlinkJoin
, cores ? [ libretro.mgba ]
}:

let
  retroarchKms = (retroarch-bare.override {
    withGamemode = false;
    withVulkan = false;
    withWayland = false;
  }).overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [ dbus ];
    configureFlags = (old.configureFlags or []) ++ [
      "--enable-opengles"
      "--enable-opengles3"
      "--enable-kms"
      "--enable-threads"
      "--enable-udev"
      "--enable-alsa"
      "--enable-pulse"
      "--disable-x11"
      "--disable-vulkan"
      "--disable-wayland"
      "--disable-qt"
    ];
  });
in
symlinkJoin {
  pname = "retroarch-h700";
  version = lib.getVersion retroarchKms;

  paths = [
    retroarchKms
    retroarch-assets
    retroarch-joypad-autoconfig
    libretro-core-info
  ] ++ cores;

  nativeBuildInputs = [ makeBinaryWrapper ];

  passthru = {
    inherit cores;
    unwrapped = retroarchKms;
  };

  postBuild = ''
    rm -f $out/bin/retroarch-cg2glsl

    mkdir -p $out/share/anbernix
    cat > $out/share/anbernix/retroarch-h700.cfg <<EOF
video_driver = "kms"
video_fullscreen = "true"
menu_driver = "ozone"
input_driver = "udev"
input_joypad_driver = "udev"
input_autodetect_enable = "false"
input_player1_joypad_index = "0"
input_player1_a_btn = "1"
input_player1_b_btn = "0"
input_player1_x_btn = "3"
input_player1_y_btn = "2"
input_player1_l_btn = "4"
input_player1_r_btn = "5"
input_player1_l2_btn = "6"
input_player1_r2_btn = "7"
input_player1_select_btn = "8"
input_player1_start_btn = "9"
input_player1_l3_btn = "11"
input_player1_r3_btn = "12"
input_player1_up_btn = "13"
input_player1_down_btn = "14"
input_player1_left_btn = "15"
input_player1_right_btn = "16"
input_player1_l_x_plus_axis = "+0"
input_player1_l_x_minus_axis = "-0"
input_player1_l_y_plus_axis = "+1"
input_player1_l_y_minus_axis = "-1"
input_player1_r_x_plus_axis = "+3"
input_player1_r_x_minus_axis = "-3"
input_player1_r_y_plus_axis = "+4"
input_player1_r_y_minus_axis = "-4"
input_menu_toggle_btn = "10"
input_enable_hotkey_btn = "10"
audio_driver = "pulse"
assets_directory = "$out/share/retroarch/assets"
joypad_autoconfig_dir = "$out/share/libretro/autoconfig"
libretro_directory = "$out/lib/retroarch/cores"
libretro_info_path = "$out/share/retroarch/cores"
quit_on_close_content = "0"
config_save_on_exit = "false"
EOF

    wrapProgram $out/bin/retroarch \
      --add-flags "--appendconfig=$out/share/anbernix/retroarch-h700.cfg"
  '';

  meta = {
    inherit (retroarchKms.meta) homepage license platforms;
    description = "RetroArch wrapped for Allwinner H700 Anbernic handhelds";
    mainProgram = "retroarch";
  };
}
