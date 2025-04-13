{ config, lib, modulesPath, pkgs, ... }:


{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  # Use the default nixpkgs channel instead of redefining it
  nixpkgs.config.allowUnfree = true;

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    nushell
    fzf
    yazi
    htop
    btop
    git
    gitAndTools.gh
    wget
    curl
    iperf3
    age
    oh-my-posh
    tmux
    ceph-client
    nmap
    helix
    bat
    sops
    compose2nix
    docker
    nodejs_20
  ];

  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

  virtualisation.oci-containers.backend = "podman";

  # Containers
  virtualisation.oci-containers.containers."homebridge-homebridge" = {
    image = "homebridge/homebridge:latest";
    volumes = [
      "/var/lib/homebridge/volumes/homebridge:/homebridge:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network=host"
    ];
  };
  
  systemd.services."podman-homebridge-homebridge" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    partOf = [
      "podman-compose-homebridge-root.target"
    ];
    wantedBy = [
      "podman-compose-homebridge-root.target"
    ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-homebridge-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/etc/nixos/age-key.txt";
  };

    services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = ":8086";
      auth-enabled = true;
      admin-user = "admin";
      admin-password = config.sops.secrets.influxdb_password.path;
    };
  };

  sops.secrets.influxdb_password = {
    sopsFile = ./influxdb-secrets.yaml;
    owner = "influxdb2";
  };

  systemd.services.iperf3 = {
    description = "iPerf3 Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.iperf3}/bin/iperf3 --server --bind 0.0.0.0 --port 5201";
      Restart = "always";
      Type = "simple";
      };
    };

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
  };
  
  networking.hostName = "homeserver"; # Set your desired hostname here
  
  systemd.network = {
    enable = true;
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # networking.firewall.allowedTCPPorts = [ 5201 8086 8581 9000 ]; # Default Homebridge port
  networking.firewall.enable = false;

  systemd.mounts = [{
    what = "debugfs";
    where = "/sys/kernel/debug";
    enable = false;
  }];

  boot.initrd.systemd.fido2.enable = false;

  time.timeZone = "America/Toronto";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    description = "Anwer Khan";
    home = "/home/deepwatrcreatur";
    extraGroups = [ "networkmanager" "wheel" "docker"];
    packages = with pkgs; [
    ];
  };
  # Locale settings
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ]; # Optional, ensures generation
    
  system.stateVersion = "25.05";
}

