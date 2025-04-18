# cloudflare-ddns.nix
{ config, pkgs, lib, ... }:

let
  # ageKeyFile = builtins.toPath ./age-key.txt;
  ageKeyFile = "/etc/nixos/age-key.txt";
  # Path to the sops-encrypted API_KEY file
  apiKeyFile = config.sops.secrets."API_KEY".path;
  apiKey = builtins.readFile apiKeyFile;

in
{
  # Define the container
  virtualisation.oci-containers.containers.cloudflare-ddns = {
    image = "oznu/cloudflare-ddns:latest";
    autoStart = true;
    volumes = [
      "/etc/nixos/cloudflare-ddns-config.json:/config.json:ro"
    ];
    environment = {
      ZONE = "deepwatercreature.com";
      PROXIED = "false";
      PUID = "1000";
      PGID = "1001";
      API_KEY_FILE = "/run/secrets/API_KEY";  # Path inside the container
    };
    # Use the decrypted API_KEY from sops
    environmentFiles = [ apiKeyFile ];

    # Configure DNS using extraOptions
    extraOptions = [
      "--dns=127.0.0.1"
      "--dns=1.1.1.1"
      "-v" "${apiKeyFile}:/run/secrets/API_KEY:ro"  # Mount the decrypted API_KEY file
];
  };

  # Configure sops to manage the API_KEY
  sops.secrets."API_KEY" = {
    sopsFile = ../secrets/cloudflare-secrets.yaml;  # Path to your sops-encrypted file
    format = "yaml";            # Format of the secrets file
  };

  # Configure the global age key file
  sops.age.keyFile = ageKeyFile;
}
