{ config, pkgs, lib, ... }:

let 
    machineName = "<selected machine>";
    commonSettings = import ./cluster/common.nix;
    machine = (import ./cluster/machines.nix pkgs)."${machineName}";
    controlMachine = "master1";
in
{
  imports =
  [ 
    ./hardware-configuration.nix
  ] ++ (if machineName == controlMachine then machine.imports else []);

  nixpkgs.config.allowUnfree = true;
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      grub = {
        device = "nodev";
        efiSupport = true;              
        enable = true;
        version = 2;
      };
    };
  };

  networking = lib.mkMerge [{
    nameservers = [
     "<DNS server IP>"
     "<another DNS server IP (optional)>"
    ];
    hostName = machineName;
    hosts = commonSettings.hosts;
    firewall = {
      enable = false;
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  } (machine.networking)];

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "fr_FR.UTF-8";
  console = {
      font = "Lat2-Terminus16";
      keyMap = "fr";
  };


  systemd = {
    tmpfiles.rules = [
      "f /etc/munge/munge.key 0400 munge munge - mungeverryweakkeybuteasytointegratoinatest"
    ];

    services.NetworkManager-wait-online.enable = false;
  };
 
    services = lib.mkMerge [{

    openssh = {
      enable = true;
      permitRootLogin = "yes";
      openFirewall = true;
    };

    pipewire = {
      pulse.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      enable = true;
    };
    
    printing.enable = true;
    
    slurm = {
      enableStools = true;
      controlMachine = controlMachine;
      partitionName = [ "standard Nodes=worker[1-2] default=YES MaxTime=INFINITE State=UP" ];
      nodeName = [ 
        "worker[1] NodeAddr=<node IP address>   CPUs=<CPU logical cores count> SocketsPerBoard=<number of CPU sockets> ThreadsPerCore=<1 or 2 usually> RealMemory=<Available RAM in Megabytes> State=UNKNOWN"
        "worker[2] NodeAddr=<node IP address>   CPUs=<CPU logical cores count> SocketsPerBoard=<number of CPU sockets> ThreadsPerCore=<1 or 2 usually> RealMemory=<Available RAM in Megabytes> State=UNKNOWN"
      ];
      extraConfig = ''
        AccountingStorageHost=master1
        AccountingStorageType=accounting_storage/slurmdbd

        SelectType=select/cons_tres
        DefMemPerCPU=1000
      '';
    };
  }
  (machine.services)];

  users = import ./users.nix; 
  fileSystems = (if machineName == controlMachine then {} else machine.remoteHome);

  environment.systemPackages = with pkgs; [
    #terminal utilities
    git
    htop
    wget
    
    #firefox
  ];

  security.pam.services.login.setLoginUid = false;

  system.stateVersion = "21.11"; 
}

