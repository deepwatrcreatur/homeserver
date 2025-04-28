{ config, lib, pkgs, ... }:

let
  # Path to your .terminfo directory in the flake
  terminfoSource = ./../terminfo;
in
{
  home.activation.installTerminfo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.terminfo"
    cp -rT "${terminfoSource}" "$HOME/.terminfo"
  '';
}

