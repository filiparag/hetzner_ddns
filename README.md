# Hetzner Dynamic DNS Daemon

Continuously update your servers' _A_ and _AAAA_ records with dynamic IP addresses.

Manage Hetzner DNS records across several domains, with various records at different TTLs, on multiple network interfaces. This portable utility helps you get it done quickly and easily.

<details>
    <summary>
      <b>Prebuilt packages</b>
    </summary>

Packages for the latest stable version can be found [here](https://github.com/filiparag/hetzner_ddns/releases/latest).

Officially supported platforms are:

- Alpine Linux
- Arch Linux ([AUR](https://aur.archlinux.org/packages/hetzner_ddns/))
- Debian / Ubuntu
- Docker ([Docker Hub](https://hub.docker.com/r/filiparag/hetzner_ddns))
- Fedora / openSUSE ([Copr](https://copr.fedorainfracloud.org/coprs/filiparag/hetzner_ddns/))
- FreeBSD ([Ports tree](https://www.freshports.org/dns/hetzner_ddns/))
- NetBSD
- OpenWrt

Feel free to contribute to [first-party support](./release) for other operating systems.

</details>

<details>
    <summary>
        <b>Manual installation</b>
    </summary>

Dependencies: `awk`, `curl`, `net-tools`, `jq`.

```shell
# Download
git clone https://github.com/filiparag/hetzner_ddns.git
cd hetzner_ddns

# Install
sudo make install

# systemd service
sudo make systemd

# FreeBSD service
sudo make freebsd-rc

# NetBSD service
sudo make netbsd-rc

# OpenRC service
sudo make openrc

# OpenWrt procd service
sudo make openwrt-rc
```

</details>

<details>
    <summary>
        <b>Deprecated version (for zones not migrated to Hetzner Console)</b>
    </summary>

  If your zones are still managed via deprecated [Hetzner DNS](https://dns.hetzner.com/) service, use [`0.2.6`](https://github.com/filiparag/hetzner_ddns/releases/tag/0.2.6) version of this utility.

</details>

## Configuration

Configuration file is formatted using JSON. For manual installation, it is located at `/usr/local/etc/hetzner_ddns.json`, while for prebuilt packages it may be moved to `/etc/`, `/etc/config/` or `/usr/pkg/etc/`.

To quickly get up and running, the following minimal configuration can be used:

```json
{
  "version": "1.0.0",
  "api_key": "****************************************************************",
  "zones": [
    {
      "domain": "example.com",
      "records": [
        {
          "name": "@/homelab/media"
        }
      ]
    }
  ]
}
```

It will update both `A` and `AAAA` records for domain root `example.com` and its subdomains `homelab` and `media`.

> [!NOTE]
> All records have to be added in the [Hetzner Console](https://console.hetzner.com/) first, and only have one record per every name and type combination. The utility will otherwise terminate to prevent unexpected modifications.
>
> An API key can be also obtained in the Console, under Security > API tokens > Generate API token, and selecting Read & Write option.
> The API key can also be configured to be read from a file, using the `api_key_file` option in the config.json file.

<details>
    <summary>
        <b>Advanced configuration</b>
    </summary>

If you need fine-grained control, the configuration can be expanded to have different TTL and egress interface per type of record. For example, you can have the `A` record of `test.example.com` subdomain use external IPv4 address of a `eth0` interface and be updated every minute, while the `AAAA` record uses `vpn1` interface which rarely changes its IPv6 address, so it can be updated hourly:

```json
{
  "domain": "example.com",
  "records": [
    {
      "name": "test",
      "type": "A",
      "ttl": 60,
      "interface": "eth0"
    },
    {
      "name": "test",
      "type": "AAAA",
      "ttl": 3600,
      "interface": "vpn1"
    }
  ]
}
```

Values for `type`, `ttl` and `interface` can be ommited, in which case reasonable defaults will be used. You can override them by adding this object to the root of the configuration tree:

```jsonc
{
  "defaults": {
    "type": "A", // Default record type (can be "A", "AAAA", or "A/AAAA")
    "ttl": 1800, // Default TTL value in seconds (60 <= TTL <= 2147483647)
    "interface": "eth2" // Default network interface name (auto-detect if unspecified)
  }
}
```

Additionally, the utility rate limits checking for changes of external IP addresses on used network interfaces. This and some other preferences can be modified by changing fields of this object:

```jsonc
{
  "settings": {
    "log_file": "", // Path to a custom configuration file
    "ip_check_cooldown": 30, // Time between subsequent checks of interface's IP address
    "request_timeout": 10, // Maximum duration of HTTP requests
    "api_url": "https://api.hetzner.cloud/v1", // URL of the Hetzner Console's API
    "ip_url": "https://ip.hetzner.com/" // URL of a service for retreiving external IP addresses
  }
}
```

An example of a configuration tree can be found [here](./hetzner_ddns.json).

</details>

## Usage

**Run on startup**

```shell
# systemd
sudo systemctl enable hetzner_ddns

# FreeBSD, NetBSD and OpenWrt
sudo service hetzner_ddns enable

# OpenRC
sudo rc-update add hetzner_ddns

```

**Start/Stop**

```shell
# systemd
sudo systemctl start/stop hetzner_ddns

# FreeBSD, NetBSD, OpenRC and OpenWrt
sudo service hetzner_ddns start/stop
```

**Reload (trigger update of all records)**

```shell
# systemd
sudo systemctl reload hetzner_ddns

# FreeBSD, NetBSD, OpenRC and OpenWrt currently lack this option
```

<details>
    <summary>
        <a id="NixOS"></a>
        <b>NixOS</b>
    </summary>

## NixOS
### load module without flakes
```nix
imports = [
  "${(pkgs.fetchFromGitHub {
    owner = "filiparag";
    repo = "hetzner_ddns";
    rev = "v1.0.1";
    # also update the hash when updating to a new version!!
    # an error with the correct sha256 will be printed when rebuilding (but only if you make it an empty string first)
    sha256 = "sha256-trouNNC2vq43hVVZ1fnJggjrsXSHQt3MGw+VkxSg5dY="
  })}/release/NixOS/nixos_module.nix"
];
```

### load module with flakes
```nix
# in flake.nix
inputs.hetzner_ddns = {
  url = "github:filiparag/hetzner_ddns";
  flake = false;
};
# in configuration.nix
imports = [ "${inputs.hetzner_ddns}/release/NixOS/nixos_module.nix" ];
```

### enable and configure
All options can be found [here](./release/NixOS/nixos_module.nix).
```nix
# basic settings
services.hetzner_ddns = {
 enable = true;
 zones = [...];
};

# advanced
services.hetzner_ddns = {
  protections = true; # enables protection settings in the systemd service. might cause permission problems with reading the api_key_file
  settings = {...}; # same as the settings in the config.json
  defaults = {...}; # same as the defaults in the config.json
  api_key_file = "/path/to/api_key_file";
  api_key = "************************";
}
systemd.services.hetzner_ddns.serviceConfig = {
  User = "myUser"; # the user under which the service will run. useful when using api_key_file but has security implications
};
```
</details>

<details>
    <summary>
        <a id="manual-usage"></a>
        <b>Manual usage and debugging</b>
    </summary>

The utility can also be run by any user on the system from the command line. For quick debugging, run it in verbose mode with a specified configuration file:

```shell
hetzner_ddns -V -c ./test_configuration.json
```

The following is the list of all optional arguments:

- `-c <file>` Use specified configuration file
- `-l <file>` Use specified log file
- `-P <file>` Use specified PID file when daemonized
- `-V` Display all log messages to stderr
- `-d` Detach from current shell and run as a deamon
- `-h` Print help and exit
- `-v` Print version and exit

</details>
