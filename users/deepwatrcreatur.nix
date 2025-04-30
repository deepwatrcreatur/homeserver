
# home/deepwatrcreatur.nix
{ config, pkgs, lib, ... }:
{
  home.username = "deepwatrcreatur";
  home.homeDirectory = "/home/deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    lsd
    fish
    # ...other packages you want...
  ];

  programs.fish = {
    enable = true;
    shellInit = ''
      set -gx EDITOR hx
      set -gx VISUAL hx
    '';
    shellAliases = {
      ls = "lsd";
      ll = "lsd -l";
      la = "lsd -a";
      lla = "lsd -la";
      ".." = "cd ..";
    };
    plugins = [
      { name = "fzf"; src = pkgs.fishPlugins.fzf; }
      { name = "z"; src = pkgs.fishPlugins.z; }
      { name = "puffer"; src = pkgs.fishPlugins.puffer; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair; }
      { name = "grc"; src = pkgs.fishPlugins.grc; }
      { name = "bobthefish"; src = pkgs.fishPlugins.bobthefish; }
    ];
  };

  # Set fish as default shell
  programs.fish.loginShellInit = ''
    if test (basename $SHELL) != "fish"
      chsh -s ${pkgs.fish}/bin/fish
    end
  '';

  # Copy .terminfo files into place
  home.file.".terminfo" = {
    source = ./terminfo; # Place your terminfo files in home/terminfo/
    recursive = true;
  };

  programs.home-manager.enable = true;
}
