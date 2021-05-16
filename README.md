# Dynamic DNS daemon for Hetzner DNS service

## Installation

### FreeBSD

```sh
sudo pkg install curl jq
git clone https://github.com/filiparag/hetzner_ddns.git
cd hetzner_ddns
sudo make install
```

## Usage

**Enable in** `/etc/rc.conf`
```
service hetzner_ddns enable
```
**Start**
```
service hetzner_ddns start
```

**Stop**
```
service hetzner_ddns stop
```

**Log file** is located at `/var/log/hetzner_ddns.log` 

## Configuration

Configuration file is located at `/usr/local/etc/hetzner_ddns.conf`

```sh
# Time between DNS record updates and also the TTL value
interval='60'

# Hetzner DNS API key
key='********************************'

# Top level domain name
domain='example.com'

# Host subdomain reecord (@ for the domain itself)
name='homelab'
```