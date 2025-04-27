# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
  };
  outputs = { self, nixpkgs, sops-nix }:
    let
      lib = nixpkgs.lib;
      # Helper function to import all .nix files from a directory
      importModules = path:
        let
          dirContents = builtins.readDir path;
          nixFiles = lib.filterAttrs (name: type:
            type == "regular" && lib.strings.hasSuffix ".nix" name
          ) dirContents;
        in
        lib.mapAttrsToList (name: _: path + "/${name}") nixFiles;
    in {
      nixosConfigurations.homeserver = lib.nixosSystem {
        system = "x86_64-linux";
        modules =
          [
            sops-nix.nixosModules.sops
          ]
          ++ (importModules ./modules)
          ++ [
            ({ config, pkgs, lib, ... }: {
              # === SOPS Configuration ===
              sops.secrets.REOLINK_CAMERA_PASSWORD = {
                sopsFile = "${self}/secrets/reolink-secrets.yaml"; # Use self to reference flake root
                owner = "hass";
                group = "hass";
                mode = "0440";
              };
              users.users.hass.extraGroups = [ "keys" ];
              systemd.services."home-assistant".serviceConfig = {
                LoadCredential = lib.mkForce null;
                EnvironmentFile = config.sops.secrets.REOLINK_CAMERA_PASSWORD.path;
              };
              systemd.services."home-assistant".wants = [ "sops-nix.service" ];
              systemd.services."home-assistant".after = [ "sops-nix.service" ];
              # === Configuration for the Custom Home Assistant Module ===
              modules.homeAssistant = {
                enable = true;
                latitude = "40.7128";
                longitude = "-74.0060";
                timeZone = "America/Toronto";
                unitSystem = "metric";
                reolink = {
                  enable = true;
                  cameras = {
                    "418" = {
                      host = "10.10.10.59";
                      username = "admin";
                      password = "!env_var REOLINK_CAMERA_PASSWORD";
                      port = 80;
                      channel = 0;
                      stream = "main";
                    };
                    "420" = {
                      host = "10.10.10.60";
                      username = "admin";
                      password = "!env_var REOLINK_CAMERA_PASSWORD";
                      port = 80;
                      channel = 0;
                      stream = "main";
                    };
                  };
                };
                extraComponents = [
                  "mqtt"
                  "zha"
                  "stream"
                  "ffmpeg"
                  "radio_browser"
                  "google_translate"
                ];
                extraPackages = py: with py; [
                  getmac
                  aiohomekit
                  pyqrcode
                  pypng
                  pillow
                  xmltodict
                  radios
                  gtts
                ];
              };
            })
          ];
      };
    };
}
