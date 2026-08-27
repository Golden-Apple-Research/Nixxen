# Home Manager Config für den Desktop-User (admin) auf tsathoggua
# Doku: https://nix-community.github.io/home-manager/
{
  config,
  pkgs,
  ...
}:

{
  home.stateVersion = "25.05";

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "alacritty";

      exec-once = [ "waybar" ];

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, Q, killactive"
        "$mod, M, exit"
        # Vollständige Config: https://wiki.hyprland.org/Configuring/
      ];
    };
  };

  programs.waybar.enable = true;
}
