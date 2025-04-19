# /etc/nixos/modules/cloudflare-ddns.nix
{ config, pkgs, lib, ... }:

let
  # Path where sops-nix will place the decrypted API_KEY file on the host
  # This path is determined by sops-nix based on the secret definition below
  apiKeyFile = config.sops.secrets."API_KEY".path;
in
{
  # Define the container
  virtualisation.oci-containers.containers.cloudflare-ddns = {
    image = "oznu/cloudflare-ddns:latest";
    autoStart = true;
    environment = {
      ZONE = "deepwatercreature.com";
      PROXIED = "false";
      API_KEY_FILE = "/run/secrets/API_KEY"; # Path inside the container
      # Add SUBDOMAIN = "your-subdomain"; if needed
      # Add RRTYPE = "A"; or "AAAA" if needed
    };
    extraOptions = [
      "--dns=1.1.1.1"
      "--dns=1.0.0.1"
      # Mount the decrypted key read-only
      # Source path `apiKeyFile` comes from the sops.secrets definition below
      # Target path `/run/secrets/API_KEY` matches the API_KEY_FILE env var
      "-v" "${apiKeyFile}:/run/secrets/API_KEY:ro"
    ];
  };

  # Configure sops-nix to manage the API_KEY secret
  sops.secrets."API_KEY" = {
    # This path is relative to this file (/etc/nixos/modules/cloudflare-ddns.nix)
    # It correctly points to /etc/nixos/secrets/cloudflare-secrets.yaml
    sopsFile = ../secrets/cloudflare-secrets.yaml;
    format = "yaml";
    # Optional: Define owner/group if needed, defaults might be sufficient
    # owner = config.users.users.root.name; # Or another user
    # group = config.users.groups.root.name; # Or another group
  };

  # No need for sops.age.keyFile or sops.enable here,
  # as they are handled globally or automatically.
}

