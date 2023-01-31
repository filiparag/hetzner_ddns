#!/bin/sh

self='hetzner_ddns'

if ! [ -z "$1" ]; then
    self="${self}.$1"
fi

# Read variabels from configuration file
if test -G "/usr/local/etc/$self.conf"; then
    . "/usr/local/etc/$self.conf"
    records_escaped="$(echo "$records" | sed 's:\*:\\\*:g')"
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
            awk "\$1==\"$1\" && \$2==\"A\" {print \$3}"
        )"
        record_ipv6="$(
            curl "https://dns.hetzner.com/api/v1/records?zone_id=$zone" \
                -H "Auth-API-Token: $key" 2>/dev/null | \
            jq -r '.records[] | .name + " " + .type + " " + .id' | \
            awk "\$1==\"$1\" && \$2==\"AAAA\" {print \$3}"
        )"
    fi
    if [ -z "$record_ipv4" ] && [ -z "$record_ipv6" ]; then
        return 1
    else
        printf '[%s] IPv4 record for %s: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1.$domain" \
            "${record_ipv4:-(missing)}" >> "/var/log/$self.log"
        printf '[%s] IPv6 record for %s: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1.$domain" \
            "${record_ipv6:-(missing)}" >> "/var/log/$self.log"
    fi
}

get_records() {
    # Get all record IDs
    for n in $records_escaped; do
        n="$(echo "$n" | sed 's:\\::')"
        if get_record "$n"; then
            records_ipv4="$records_ipv4$n=$record_ipv4 "
            records_ipv6="$records_ipv6$n=$record_ipv6 "
        else
            printf '[%s] Missing both records for %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
                "$n.$domain" >> "/var/log/$self.log"
        fi
    done
}

get_record_ip_addr() {
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
    if [ -z "$ipv4_rec" ] && [ -z "$ipv6_rec" ]; then
        return 1
    fi
}

get_my_ip_addr() {
    # Get current public IP address
    ipv4_cur="$(
        curl 'http://ipv4.whatismyip.akamai.com/' 2>/dev/null
    )"
    ipv6_cur="$(
        curl 'http://ipv6.whatismyip.akamai.com/' 2>/dev/null
    )"
    if [ -z "$ipv4_cur" ] && [ -z "$ipv6_cur" ]; then
        return 1
    fi
}

set_record() {
    # Update record if IP address has changed
    if [ -n "$record_ipv4" ] && [ -n "$ipv4_cur" ] && [ "$ipv4_cur" != "$ipv4_rec" ]; then
        curl -X "PUT" "https://dns.hetzner.com/api/v1/records/$record_ipv4" \
            -H 'Content-Type: application/json' \
            -H "Auth-API-Token: $key" \
            -d "{
            \"value\": \"$ipv4_cur\",
            \"ttl\": $interval,
            \"type\": \"A\",
            \"name\": \"$n\",
            \"zone_id\": \"$zone\"
            }" 1>/dev/null 2>/dev/null &&
        printf "[%s] Update IPv4 for %s: %s => %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$n.$domain" "$ipv4_rec" "$ipv4_cur" >> "/var/log/$self.log"
    fi
    if [ -n "$record_ipv6" ] && [ -n "$ipv6_cur" ] && [ "$ipv6_cur" != "$ipv6_rec" ]; then
        curl -X "PUT" "https://dns.hetzner.com/api/v1/records/$record_ipv6" \
            -H 'Content-Type: application/json' \
            -H "Auth-API-Token: $key" \
            -d "{
            \"value\": \"$ipv6_cur\",
            \"ttl\": $interval,
            \"type\": \"AAAA\",
            \"name\": \"$n\",
            \"zone_id\": \"$zone\"
            }" 1>/dev/null 2>/dev/null &&
        printf "[%s] Update IPv6 for %s: %s => %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$n.$domain" "$ipv6_rec" "$ipv6_cur" >> "/var/log/$self.log"
    fi
}

pick_record() {
    # Get record ID from array
    echo "$2" | \
    awk "{
        for(i=1;i<=NF;i++){
            n=\$i;gsub(/=.*/,\"\",n);
            r=\$i;gsub(/.*=/,\"\",r);
            if(n==\"$1\"){
                print r;break
            }
        }}"
}

set_records() {
    # Get my public IP address
    if get_my_ip_addr; then
        # Update all records if possible
        for n in $records_escaped; do
            n="$(echo "$n" | sed 's:\\::')"
            record_ipv4="$(pick_record "$n" "$records_ipv4")"
            record_ipv6="$(pick_record "$n" "$records_ipv6")"
            if [ -n "$record_ipv4" ] || [ -n "$record_ipv6" ]; then
                get_record_ip_addr && set_record
            fi
        done
    fi
}

run_ddns() {
    printf '[%s] Started Hetzner DDNS daemon\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
                >> "/var/log/$self.log"

    while ! get_zone || ! get_records; do
        sleep $((interval/2+1))
    done

    while true; do
        set_records
        sleep "$interval"
    done
}

if [ "$1" = '--daemon' ]; then
    # Deamonize and write PID to file
    if touch "/var/run/$self.pid";
    then
        run_ddns &
        echo $! > "/var/run/$self.pid"
    else
        >&2 echo 'unable to daemonize'
        exit 2
    fi
else
    # Run in foreground
    run_ddns
fi
