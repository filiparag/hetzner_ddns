# Hetzner Dynamic DNS Daemon

A simple daemon to continuously update Hetzner DNS
*A* and *AAAA* records for your server with a dynamic IP address.

It features support for multiple subdomain records with painless
configuration and administration.

## Installation

### Prebuilt packages

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
sudo make rc.d

# OpenRC service
sudo make openrc
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
```

To obtain an **API key**, go to [Hetzner DNS Console](https://dns.hetzner.com/settings/api-token).

**Prebuilt packages**

Default configuration location differs in prebuilt packages:

- Linux disttributions: `/etc/hetzner_ddns.conf`
- FreeBSD: `/usr/local/etc/hetzner_ddns.conf`

## Usage

**Run on startup**
```ini
# systemd
sudo systemctl enable hetzner_ddns

# FreeBSD
sudo service hetzner_ddns enable

# OpenRC
sudo rc-update add hetzner_ddns
```

**Start/Stop**
```ini
# systemd
sudo systemctl start/stop hetzner_ddns

# FreeBSD and OpenRC
sudo service hetzner_ddns start/stop
```

**Log file** is located at `/var/log/hetzner_ddns.log` 

## Privacy notice

This script relies on Akamai's [What's My IP](http://whatismyip.akamai.com/)
service to retrieve public IP address.