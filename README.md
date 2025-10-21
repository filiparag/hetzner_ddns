> [!IMPORTANT]
> Hetzner recently changed how their DNS service works. If you have migrated your DNS zones to the new system under Hetzner Console, use the [beta version](https://github.com/filiparag/hetzner_ddns/tree/rrsets) of this utility, which is currently in testing. Please report [here](https://github.com/filiparag/hetzner_ddns/issues/27) if you encounter any issues.

# Hetzner Dynamic DNS Daemon

A simple daemon to continuously update Hetzner DNS
_A_ and _AAAA_ records for your server with a dynamic IP address.

It features support for multiple subdomain records with painless
configuration and administration.

## Installation

### Prebuilt packages

Officially supported operating systems:

- Alpine Linux
- Arch Linux ([AUR](https://aur.archlinux.org/packages/hetzner_ddns/))
- Debian / Ubuntu
- Docker ([Docker Hub](https://hub.docker.com/r/filiparag/hetzner_ddns))
- Fedora / openSUSE ([Copr](https://copr.fedorainfracloud.org/coprs/filiparag/hetzner_ddns/))
- FreeBSD ([Ports tree](https://www.freshports.org/dns/hetzner_ddns/))
- NetBSD
- OpenWrt

Packages for the latest stable version can be found
[here](https://github.com/filiparag/hetzner_ddns/releases/latest).

Feel free to contribute to [first-party support](./release) for other operating systems.

### Manual Installation

Dependencies: `awk`, `curl`, `jq`.

```ini
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

## Configuration

Configuration file is located at `/usr/local/etc/hetzner_ddns.conf`

```sh
# Seconds between updates / TTL value
interval='60'

# Hetzner DNS API key
key='18fe3b02339b23ef2418f9feda1b69ef'

# Top level domain name
domain='example.com'

# Space separated host subdomains (@ for domain itself)
records='homelab media vpn'

# Enable updating A records (IPv4)
ipv4=true

# Enable updating AAAA records (IPv6)
ipv6=true
```

To obtain an **API key**, go to [Hetzner DNS Console](https://dns.hetzner.com/settings/api-token).

### Configuration for prebuilt packages

Default configuration location differs in prebuilt packages:

- Linux distributions: `/etc/hetzner_ddns.conf`
- FreeBSD: `/usr/local/etc/hetzner_ddns.conf`
- NetBSD: `/usr/pkg/etc/hetzner_ddns.conf`
- OpenWrt: `/etc/config/hetzner_ddns.conf`

### Manage records for multiple domains

Currently, this utility supports management of one domain per daemon.
If you have multiple domains, use CNAME records to point them to one
the daemon will manage, as shown in the following example:

```sh
# Managed domain (master.tld)
@		IN	A	    1.2.3.4
@		IN	AAAA	1:2:3:4::

# Other domain
service		IN	CNAME	master.tld.
```

### Multiple daemon instances for **systemd**

If your operating system relies on systemd, you can easily run
multiple daemons as shown below:

```ini
# Create configuration file for foobar.tld domain
sudo cp -p /usr/local/etc/hetzner_ddns.conf.sample /usr/local/etc/hetzner_ddns.foobar.conf

# Modify created file to reflect your preferences

# Enable and start foobar.tld's daemon
sudo systemctl enable hetzner_ddns@foobar
```

## Usage

**Run on startup**

```ini
# systemd
sudo systemctl enable hetzner_ddns

# FreeBSD, NetBSD and OpenWrt
sudo service hetzner_ddns enable

# OpenRC
sudo rc-update add hetzner_ddns
```

**Start/Stop**

```ini
# systemd
sudo systemctl start/stop hetzner_ddns

# FreeBSD, NetBSD, OpenRC and OpenWrt
sudo service hetzner_ddns start/stop
```

**Log file** is located at `/var/log/hetzner_ddns.log`
