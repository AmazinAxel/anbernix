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
video_driver = "gl"
video_fullscreen = "true"
video_smooth = "false"
video_swap_interval = "0"
aspect_ratio_index = "22"
video_aspect_ratio = "1.333300"
menu_driver = "rgui"
input_driver = "udev"
input_joypad_driver = "udev"
input_autodetect_enable = "false"
input_hotkey_block_delay = "5"
input_max_users = "8"
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
input_player1_r_x_plus_axis = "+3"
input_player1_r_x_minus_axis = "-3"
input_player1_r_y_plus_axis = "+4"
input_player1_r_y_minus_axis = "-4"
input_player1_l_x_plus_axis = "+0"
input_player1_l_x_minus_axis = "-0"
input_player1_l_y_plus_axis = "+1"
input_player1_l_y_minus_axis = "-1"
input_menu_toggle_btn = "10"
input_enable_hotkey_btn = "10"
input_toggle_fast_forward_btn = "7"
audio_driver = "pulse"
audio_sync = "false"
audio_volume = "1.500000"
assets_directory = "$out/share/retroarch/assets"
joypad_autoconfig_dir = "$out/share/libretro/autoconfig"
libretro_directory = "$out/lib/retroarch/cores"
libretro_info_path = "$out/share/retroarch/cores"
savefile_directory = "~/retroarch/saves"
savestate_directory = "~/retroarch/states"
system_directory = "~/retroarch/system"
input_remapping_directory = "~/retroarch/remaps"
screenshot_directory = "~/retroarch/screenshots"
autosave_interval = "60"
auto_overrides_enable = "false"
auto_remaps_enable = "false"
core_info_cache_enable = "true"
pause_nonactive = "false"
savestate_auto_load = "true"
savestate_auto_save = "true"
fastforward_ratio = "1.500000"
menu_show_configurations = "false"
menu_show_core_updater = "false"
menu_show_online_updater = "false"
menu_show_quit_retroarch = "false"
menu_show_restart_retroarch = "false"
menu_swap_ok_cancel_buttons = "false"
rgui_menu_color_theme = "23"
rgui_particle_effect = "2"
rgui_particle_effect_speed = "0.700000"
quit_on_close_content = "0"
config_save_on_exit = "false"
EOF

    wrapProgram $out/bin/retroarch \
      --add-flags "--config $out/share/anbernix/retroarch-h700.cfg"
  '';

  meta = {
    inherit (retroarchKms.meta) homepage license platforms;
    description = "RetroArch wrapped for Allwinner H700 Anbernic handhelds";
    mainProgram = "retroarch";
  };
}
