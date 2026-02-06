{ lib, pkgs, config, ... }:

let
  cfg = config.services.hetzner_ddns;
  removeNulls = value:
    if builtins.isAttrs value then
      lib.mapAttrs (n: v: removeNulls v) (lib.filterAttrs (n: v: v != null) value)
    else if builtins.isList value then
      builtins.map removeNulls (builtins.filter (v: v != null) value)
    else
      value;
  filterConfig = config: lib.filterAttrs (n: v: n != "package" || n == "enable" || n == "protections") (removeNulls config);
in
{
  options.services.hetzner_ddns = {
    enable = lib.mkEnableOption "Enable hetzner_ddns service from https://github.com/filiparag/hetzner_ddns";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./default.nix {};
      description = "The package providing the hetzner_ddns executable/shell-script.";
    };
    
    protections = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Sets security protections for the systemd service.";
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = cfg.package.version;
      description = "Configuration version string.";
    };

    api_key = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Key for the Hetzner API.";
    };
    
    api_key_file = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to file containing API key for the Hetzner API.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          log_file = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "log file";
          };
          
          ip_check_cooldown = lib.mkOption {
            type = lib.types.ints.positive;
            default = 30;
            description = "Cooldown time in seconds between IP address checks.";
          };
          
          request_timeout = lib.mkOption {
            type = lib.types.ints.positive;
            default = 10;
            description = "Timeout for API requests in seconds.";
          };
          
          api_url = lib.mkOption {
            type = lib.types.str;
            default = "https://api.hetzner.cloud/v1";
            description = "API URL for Hetzner DNS service.";
          };
          
          ip_url = lib.mkOption {
            type = lib.types.str;
            default = "https://ip.hetzner.com/";
            description = "URL for fetching public IP address.";
          };
          
        };
      };
      default = {};
      description = "settings values";
    };
    
    defaults = lib.mkOption {
      type = lib.types.submodule {
        options = {
          type = lib.mkOption {
            type = lib.types.str;
            default = "A";
            description = "Default record type for zones. can be A or AAAA";
          };
          ttl = lib.mkOption {
            type = lib.types.int;
            default = 60;
            description = "Default TTL for records.";
          };
          interface = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Default network interface for a zone";
          };
        };
      };
      default = {};
      description = "Default values for each zone entry.";
    };

    zones = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "Domain name for this zone.";
          };

          records = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                type = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Record type 'A' or 'AAAA'";
                };

                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Name of the DNS record.";
                };

                ttl = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  default = null;
                  description = "TTL for this record. Null means default TTL.";
                };

                interface = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Optional interface name for dynamic addressing.";
                };
              };
            });
            default = [];
            description = "List of DNS records for this zone.";
          };
        };
      });
      default = [];
      description = "List of zones and their DNS record sets.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.hetzner_ddns = {
      enable = true;
      description = "hetzner_ddns service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        type = "simple";
        ExecStart = "${lib.getExe cfg.package} -V -c ${pkgs.writeText "hetzner_ddns.json" "${builtins.toJSON (filterConfig cfg)}"}";
        Restart = "always";
        RestartSec = 60;
        DynamicUser = true;
        
      } // (if cfg.protections == true then {
        PermissionsStartOnly = true;
        NoNewPrivileges = "yes";
        PrivateTmp = "yes";
        ProtectSystem = "full";
        ProtectHome = "yes";
        ProtectControlGroups = "yes";
        ProtectKernelModules = "yes";
        ProtectKernelTunables = "yes";
        MemoryDenyWriteExecute = "yes";
        LockPersonality = "yes";
      } else {});
    };
  };
}
