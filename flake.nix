# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, sops-nix }: {
    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        sops-nix.nixosModules.sops  # Use the sops-nix module from the flake input
        ./cloudflare-ddns.nix       # Your custom module
        ./configuration.nix         # Your existing configuration
        ./kasa-collector.nix
        ./tplink-energy-monitor.nix
        ./modules/home-assistant.nix

# Configure Home Assistant in your main configuration
          ({ ... }: {
            modules.homeAssistant = {
              enable = true;
              latitude = "40.7128"; # Replace with your coordinates
              longitude = "-74.0060";
              timeZone = "America/Toronto";
              unitSystem = "metric";
              
              # Enable TP-Link Kasa devices
              tplink = {
                enable = true;
                discoveryEnabled = true; # Set to false if you prefer manual configuration
                devices = {
                  "Kitchen Smart Plug" = "10.10.14.12";
                  "Living Room Energy Monitor" = "10.10.14.13";
                  # Add more devices as needed
                };
              };
              
              # Enable Reolink cameras
              reolink = {
                enable = true;
                cameras = {
                  "418" = {
                    host = "10.10.10.59";
                    username = "admin";
                    password = "1darogha"; # Consider using a secret management solution
                    port = 80;
                    channel = 0;
                    stream = "main"; # Use "main" for HD, "sub" for SD
                  };
                  "420" = {
                    host = "10.10.10.60";
                    username = "admin";
                    password = "1darogha";
                    port = 80;
                    channel = 0;
                    stream = "main";
                  };
                };
              };
              
              # Other Home Assistant components you might need
              extraComponents = [
                "mqtt"
                "zha"
                "stream" # Required for camera streaming
                "ffmpeg" # Required for video processing
              ];
              
              # Any additional Python packages needed
              extraPackages = py: with py; [
                getmac
                aiohomekit
                pyqrcode
                pypng
                pillow
                xmltodict
                # Other Python packages
              ];
            };
          })
        ];
      };
    };
#  };
}

