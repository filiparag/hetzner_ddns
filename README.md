# Dynamic DNS daemon for Hetzner DNS

This script updates host's *A* and *AAAA* records on 
Hetzner DNS whenever the IP address changes.

## Installation

### Dependencies

- `awk`
- `curl`
- `jq`

### Install

```ini
# Download
git clone https://github.com/filiparag/hetzner_ddns.git
cd hetzner_ddns

# Install
sudo make install

# FreeBSD service
sudo make rc.d

# OpenRC service
sudo make openrc

# systemd service
sudo make systemd
```
## Usage

**Run on startup**
```ini
# FreeBSD
sudo service hetzner_ddns enable

# OpenRC
sudo rc-update add hetzner_ddns

# systemd
sudo systemctl enable hetzner_ddns
```

**Start/Stop**
```ini
# FreeBSD and OpenRC
sudo service hetzner_ddns start/stop

# systemd
sudo systemctl start/stop hetzner_ddns
```

**Log file** is located at `/var/log/hetzner_ddns.log` 

## Configuration

Configuration file is located at `/usr/local/etc/hetzner_ddns.conf`

```sh
# Seconds between updates / TTL value
interval='60'

# Hetzner DNS API key
key='********************************'

# Top level domain name
domain='example.com'

# Host subdomain reecord (@ for the domain itself)
name='homelab'
```

To obtain an API key, go to [Hetzner DNS Console](https://dns.hetzner.com/settings/api-token).

## Privacy notice

This script relies on Akamai's [What's My IP](http://whatismyip.akamai.com/)
service to retrieve public IP address.