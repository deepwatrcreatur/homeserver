{ config, lib, modulesPath, pkgs, ... }:


{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  # Use the default nixpkgs channel instead of redefining it
  nixpkgs.config.allowUnfree = true;

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
    sops
    age
    oh-my-posh
    tmux
    ceph-client
    helix
    bat
    docker
  ];

  virtualisation.docker.enable = true;

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
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  networking.firewall.allowedTCPPorts = [ 8581 ]; # Default Homebridge port

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
  i18n.defaultLocale = "en_US.utf8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ]; # Optional, ensures generation
    
  system.stateVersion = "25.05";
}

