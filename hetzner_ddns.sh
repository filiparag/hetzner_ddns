#!/bin/sh

self='hetzner_ddns'

# Read variabels from configuration file
if test -G "/usr/local/etc/$self.conf"; then
    . "/usr/local/etc/$self.conf"
else
    >&2 echo 'unable to read configuration file'
    exit 78
fi

# Check dependencies
if ! command -v curl > /dev/null || \
   ! command -v awk > /dev/null || \
   ! command -v jq > /dev/null
then
    >&2 echo 'missing dependency'
    exit 1
fi

# Check logging support
if ! touch "/var/log/$self.log";
then
    >&2 echo 'unable to open logfile'
    exit 2
fi

get_zone() {
    # Get zone ID
    zone="$(
        curl "https://dns.hetzner.com/api/v1/zones" \
            -H "Auth-API-Token: $key" 2>/dev/null | \
        jq -r '.zones[] | .name + " " + .id' | \
        awk "\$1==\"$domain\" {print \$2}"
    )"
    if [ -z "$zone" ]; then
        return 1
    else
        printf '[%s] Zone for %s: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$domain" "$zone" >> "/var/log/$self.log"
    fi
}

get_record() {
    # Get record IDs
    if [ -n "$zone" ]; then
        record_ipv4="$(
            curl "https://dns.hetzner.com/api/v1/records?zone_id=$zone" \
                -H "Auth-API-Token: $key" 2>/dev/null | \
            jq -r '.records[] | .name + " " + .type + " " + .id' | \
            awk "\$1==\"$name\" && \$2==\"A\" {print \$3}"
        )"
        record_ipv6="$(
            curl "https://dns.hetzner.com/api/v1/records?zone_id=$zone" \
                -H "Auth-API-Token: $key" 2>/dev/null | \
            jq -r '.records[] | .name + " " + .type + " " + .id' | \
            awk "\$1==\"$name\" && \$2==\"AAAA\" {print \$3}"
        )"
    fi
    if [ -z "$record_ipv4" ] && [ -z "$record_ipv6" ]; then
        return 11
    else
        printf '[%s] Record for IPv4: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$record_ipv4" >> "/var/log/$self.log"
        printf '[%s] Record for IPv6: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$record_ipv6" >> "/var/log/$self.log"
    fi
}

get_ip_addr() {
    # Get record's IP address
    if [ -n "$record_ipv4" ]; then
        ipv4_rec="$(
            curl "https://dns.hetzner.com/api/v1/records/$record_ipv4" \
                -H "Auth-API-Token: $key" 2>/dev/null | \
            jq -r '.record.value'
        )"
    fi
    if [ -n "$record_ipv6" ]; then
        ipv6_rec="$(
            curl "https://dns.hetzner.com/api/v1/records/$record_ipv6" \
                -H "Auth-API-Token: $key" 2>/dev/null | \
            jq -r '.record.value'
        )"
    fi
    # Get current IP address
    if [ -n "$record_ipv4" ]; then
        ipv4_cur="$(
            curl 'http://ipv4.whatismyip.akamai.com/' 2>/dev/null
        )"
    fi
    if [ -n "$record_ipv6" ]; then
        ipv6_cur="$(
            curl 'http://ipv6.whatismyip.akamai.com/' 2>/dev/null
        )"
    fi
    if [ -z "$ipv4_cur" ] && [ -z "$ipv6_cur" ]; then
        return 1
    fi
}

set_record() {
    # Update record if IP address has changed
    if [ -n "$ipv4_cur" ] && [ "$ipv4_cur" != "$ipv4_rec" ]; then
        curl -X "PUT" "https://dns.hetzner.com/api/v1/records/$record_ipv4" \
            -H 'Content-Type: application/json' \
            -H "Auth-API-Token: $key" \
            -d "{
            \"value\": \"$ipv4_cur\",
            \"ttl\": $interval,
            \"type\": \"A\",
            \"name\": \"$name\",
            \"zone_id\": \"$zone\"
            }" 1>/dev/null 2>/dev/null &&
        printf "[%s] Update IPv4: %s -> %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$ipv4_rec" "$ipv4_cur" >> "/var/log/$self.log"
    fi
    if [ -n "$ipv6_cur" ] && [ "$ipv6_cur" != "$ipv6_rec" ]; then
        curl -X "PUT" "https://dns.hetzner.com/api/v1/records/$record_ipv6" \
            -H 'Content-Type: application/json' \
            -H "Auth-API-Token: $key" \
            -d "{
            \"value\": \"$ipv6_cur\",
            \"ttl\": $interval,
            \"type\": \"AAAA\",
            \"name\": \"$name\",
            \"zone_id\": \"$zone\"
            }" 1>/dev/null 2>/dev/null &&
        printf "[%s] Update IPv6: %s -> %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$ipv6_rec" "$ipv6_cur" >> "/var/log/$self.log"
    fi
}

printf '[%s] Started Hetzner DDNS daemon\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
            >> "/var/log/$self.log"

while ! get_zone || ! get_record; do
    sleep $((interval/2+1))
done

while true; do
    get_ip_addr
    set_record
    sleep "$interval"
done

