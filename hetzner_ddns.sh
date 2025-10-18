#!/bin/sh

version='1.0.0'
log_file='./hetzner_ddns.log'
conf_file='./hetzner_ddns.json'
api_url='https://api.hetzner.cloud/v1'

log() {
    printf '[%s] %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")" "$1" | >&2 tee -a "$log_file"
}

        fi
    done
    if [ -z "$records_ipv4" ] && [ -z "$records_ipv6" ]; then
        printf '[%s] Error: No applicable records found %s\n' \
                "$(date '+%Y-%m-%d %H:%M:%S')" "$domain" | tee -a "/var/log/$self.log"
        return 1
    fi
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
    if [ -n "$record_ipv4" ]; then
        if [ -z "$ipv4_rec" ] || [ "$ipv4_rec" = 'null' ]; then
            printf '[%s] Warning: Unable to fetch previous IPv4 address for %s\n' \
                "$(date '+%Y-%m-%d %H:%M:%S')" "$current_record.$domain" | tee -a "/var/log/$self.log"
            ipv4_rec=''
        fi;
    fi
     if [ -n "$record_ipv6" ]; then
        if [ -z "$ipv6_rec" ] || [ "$ipv6_rec" = 'null' ]; then
            printf '[%s] Warning: Unable to fetch previous IPv6 address for %s\n' \
                "$(date '+%Y-%m-%d %H:%M:%S')" "$current_record.$domain" | tee -a "/var/log/$self.log"
            ipv6_rec=''
        fi;
    fi
    if [ -z "$ipv4_rec" ] && [ -z "$ipv6_rec" ]; then
        return 1
    fi
}

get_my_ip_addr() {
    # Get current public IP address
    if [ "$ipv4" = 'true' ]; then
        ipv4_cur="$(
            curl -4 'https://ip.hetzner.com/' 2>/dev/null
        )"
    fi
    if [ "$ipv6" = 'true' ]; then
        ipv6_cur="$(
            curl -6 'https://ip.hetzner.com/' 2>/dev/null | sed 's/:$/:1/g'
        )"
    fi
    if [ -z "$ipv4_cur" ] && [ -z "$ipv6_cur" ]; then
        printf '[%s] Error: Unable to fetch current self IP address\n' \
            "$(date '+%Y-%m-%d %H:%M:%S')" | tee -a "/var/log/$self.log"
        return 1
    fi
}

set_record() {
    # Update record if IP address has changed
    if [ "$ipv4" = 'true' ] && [ -n "$record_ipv4" ] && [ -n "$ipv4_cur" ] && [ "$ipv4_cur" != "$ipv4_rec" ]; then
        curl -X "PUT" "https://dns.hetzner.com/api/v1/records/$record_ipv4" \
            -H 'Content-Type: application/json' \
            -H "Auth-API-Token: $key" \
            -d "{
            \"value\": \"$ipv4_cur\",
            \"ttl\": $interval,
            \"type\": \"A\",
            \"name\": \"$current_record\",
            \"zone_id\": \"$zone\"
            }" 1>/dev/null 2>/dev/null &&
        printf "[%s] Update IPv4 for %s: %s => %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$current_record.$domain" "$ipv4_rec" "$ipv4_cur" | tee -a "/var/log/$self.log"
    fi
    if [ "$ipv6" = 'true' ] && [ -n "$record_ipv6" ] && [ -n "$ipv6_cur" ] && [ "$ipv6_cur" != "$ipv6_rec" ]; then
        curl -X "PUT" "https://dns.hetzner.com/api/v1/records/$record_ipv6" \
            -H 'Content-Type: application/json' \
            -H "Auth-API-Token: $key" \
            -d "{
            \"value\": \"$ipv6_cur\",
            \"ttl\": $interval,
            \"type\": \"AAAA\",
            \"name\": \"$current_record\",
            \"zone_id\": \"$zone\"
            }" 1>/dev/null 2>/dev/null &&
        printf "[%s] Update IPv6 for %s: %s => %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$current_record.$domain" "$ipv6_rec" "$ipv6_cur" | tee -a "/var/log/$self.log"
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
        for current_record in $records_escaped; do
            current_record="$(echo "$current_record" | sed 's:\\::')"
            record_ipv4="$(pick_record "$current_record" "$records_ipv4")"
            record_ipv6="$(pick_record "$current_record" "$records_ipv6")"
            if [ -n "$record_ipv4" ] || [ -n "$record_ipv6" ]; then
                get_record_ip_addr && set_record
            fi
        done
    fi
}

run_ddns() {
    printf '[%s] Started Hetzner DDNS daemon\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
                | tee -a "/var/log/$self.log"

    read_configuration
    test_api_key

    while ! get_zone || ! get_records; do
        sleep $((interval/2+1))
        printf '[%s] Retrying to fetch zone and record data\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
                | tee -a "/var/log/$self.log"
    done

    printf '[%s] Configuration successful\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" | tee -a "/var/log/$self.log"
    printf '[%s] Watching for IP address and record changes\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" | tee -a "/var/log/$self.log"

    while true; do
        set_records
        sleep "$interval"
    done
}

if [ "$daemon" = '1' ]; then
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
