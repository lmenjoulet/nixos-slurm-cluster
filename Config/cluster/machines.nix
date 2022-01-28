let

  internalGatewayAddress = "192.168.2.1";
  
  baseConfig = {
    services = {
      slurm = {
        client.enable = true;
      };
    };
      
    remoteHome = {
      "/home" = {
        device = "master1:home";
        fsType = "nfs";
      };
    };
  };
in

pkgs: rec {


  master1 = 
  let
    externalAddress = "<static IP address, not needed if you use DHCP to connect your master node to the internet>";
    
    internalInterface = "<network card internal interface name>";
    externalInterface = "<network card external interface name>";
  in
  {
    
    imports = [ 
      (import ../nixos-router/mkRouter.nix {
        internalInterface = internalInterface;
        externalInterface = externalInterface;
      })
    ];

    networking = {
      defaultGateway = {
        address = "<Static default gateway IP, not needed if DHCP is used>";
        interface = externalInterface;
      };
      interfaces = {
        "${externalInterface}" = {
          useDHCP = false;
          ipv4 = {
            addresses = [
              {
                address = externalAddress;
                prefixLength = 24;
              }
            ];
          };
        };
      };
    };
    

    services = {
      
      nfs.server = {
        enable = true;
        exports  = ''
          /home ${internalGatewayAddress}/24(rw,no_subtree_check,no_root_squash,rw)
        '';
      };

      dnsmasq = {
        enable = true;
      };

      mysql = {
        enable = true;
        package = pkgs.mariadb;
        initialScript = pkgs.writeText "mysql-init.sql" ''
          CREATE USER 'slurm'@'localhost' IDENTIFIED BY '<databasePassword>';
          GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'localhost';
          GRANT ALL PRIVILEGES ON localhost.* TO 'slurm'@'localhost';
        '';
        ensureDatabases = [ "slurm_acct_db" "localhost" ];
        ensureUsers = [{
          ensurePermissions = {
            "slurm_acct_db.*" = "ALL PRIVILEGES";
            "localhost.*" = "ALL PRIVILEGES";
          };
          name = "slurm";
        }];
        settings = {
          mysqld = {
            innodb_buffer_pool_size = "1024M";
            innodb_log_file_size = "64M";
            innodb_lock_wait_timeout=900;
          };
        };
      };

      slurm = {
        server.enable = true;
        dbdserver = {
          enable = true;
          dbdHost = "master1";
          storagePassFile = "<path/to/the/databasePassword>";
        };
        extraConfig = ''
          MaxMemPerCPU  = 4096
        '';
      };

      xserver = {
        videoDrivers = [ "nvidia" ]; #needed if you use an nvidia card
        desktopManager = {
          xfce.enable = true; #xfce is used here as the desktop environnment, but other options are possible.
          xterm.enable = true;
        };
        displayManager.lightdm.enable = true;
        enable = true;
        layout = "fr";
        xkbOptions = "eurosign:e";
      };
    };
  };

  worker1 = 
    let
      interface = "<worker1 network interface name>";
    in{
      networking = {
          interfaces = {
            "${interface}" = {
                useDHCP = true;
              };
            };
      };    
    } // baseConfig;

  worker2 = 
    let
      interface = "worker2 network interface name";
    in{
      networking = {
          interfaces = {
            "${interface}" = {
                useDHCP = true;
              };
            };
      };    
    } // baseConfig;
}
