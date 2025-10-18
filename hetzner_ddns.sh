#!/bin/sh

version='1.0.0'
log_file='./hetzner_ddns.log'
conf_file='./hetzner_ddns.json'
api_url='https://api.hetzner.cloud/v1'

log() {
    printf '[%s] %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")" "$1" | >&2 tee -a "$log_file"
}

test_dependencies() {
    for d in awk curl jq netstat; do
        if ! command -v "$d" 1> /dev/null 2> /dev/null; then
            log "Fatal error: Missing dependency $d"
            exit 1
        fi
    done
}

test_conf_file() {
    # Test if file exists
    if ! test -f "$conf_file"; then
        log "Fatal error: Configuration file '$conf_file' not found"
        exit 1
    fi
    if ! test -r "$conf_file"; then
        log "Fatal error: Configuration file is not readable"
        exit 1
    fi
    # Check version
    version_major="$(jq -r '.version | split(".") | .[0]' "$conf_file")"
    if [ "$version_major" -ne 1 ] ; then
        log "Fatal error: Incompatible configuration file version"
        exit 1
    fi
    log "Using configuration file '$conf_file'"
}

load_and_test_api_key() {
    api_key="$(jq -r '.api_key' "$conf_file")"
    if [ -z "$api_key" ] || [ "$api_key" = 'null' ]; then
        log "Fatal error: API key not provided"
        exit 1
    fi
    if [ "$(printf '%s' "$api_key" | wc -m)" != 64 ]; then
        log "Fatal error: Invalid API key format"
        exit 1
    fi
    if [ "$(curl \
	    -H "Authorization: Bearer $api_key" \
        -I -w "%{http_code}" \
        -s -o /dev/null \
	    "$api_url/zones")" != 200 ]; then
        log "Fatal error: Provided API key is unauthorized"
        exit 1
    fi
    log "Loaded valid API key"
}

load_records() {
    records="$(jq \
        --arg default_interface "$(
            netstat -rn | awk '$1 == "default" || $1 == "0.0.0.0" {print $NF; exit}'
        )" \
        --arg default_ttl 60 \
        --arg default_type 'A/AAAA' \
        -r '
        (
          (.defaults // {
            type: $default_type,
            interface: $default_interface,
            ttl: $default_ttl,
          })
          | {
            type: (.type // $default_type),
            interface: (.interface // $default_interface),
            ttl: (.ttl // $default_ttl)
          }
        ) as $defaults
        | .zones[]
        | .domain as $domain
        | .records[]
        | {
            domain: $domain,
            type: (.type // $defaults.type),
            name: .name,
            interface: (.interface // $defaults.interface),
            ttl: (.ttl // $defaults.ttl)
          }
        | (.name | split("/")) as $names
        | (.type | split("/")) as $types
        | $names[] as $name
        | $types[] as $type
        | "\($domain)\t\($name)\t\($type)\t\(.ttl)\t\(.interface)"
    ' "$conf_file")"
}

test_interfaces() {
    for i in $(printf '%s' "$records" | cut -f5 | sort | uniq -d); do
        if ! test -f "/sys/class/net/$i/operstate"; then
            log "Fatal error: Missing network interface '$i'"
            exit 1
        fi
    done
    log "All used network interfaces exist"
}

test_domains() {
    for d in $(printf '%s' "$records" | cut -f1 | sort | uniq -d); do
        if [ "$(curl \
            -H "Authorization: Bearer $api_key" \
            -I -w "%{http_code}" \
            -s -o /dev/null \
            "$api_url/zones/$d/rrsets")" != 200 ]; then
            log "Fatal error: Unable to access zone of domain '$d'"
            exit 1
        fi
    done
    log "All domain zones are accessible using provided API key"
}

test_records() {
    record_duplicates="$(printf '%s' "$records" | cut -f1-3 | sort | uniq -d)"
    # Check duplicate entries
    if [ -n "$record_duplicates" ]; then
        while IFS="$(printf '\t')" read -r record_domain record_name record_type; do
            log "Fatal error: Multiple entries for record '$record_name' of type '$record_type' for domain '$record_domain'"
            exit 1
done <<EOF
$record_duplicates
EOF
    fi
    while IFS="$(printf '\t')" read -r record_domain record_name record_type record_ttl record_interface; do
        # Check record type
        if [ "$record_type" != 'A' ] && [ "$record_type" != 'AAAA' ]; then
            log "Fatal error: Record '$record_name' of type '$record_type' for domain '$record_domain' is not supported"
            exit 1
        fi
        # Check record TTL
        if [ "$record_ttl" -lt 60 ] || [ "$record_ttl" -gt 2147483647 ]; then
            log "Fatal error: $record_type record '$record_name' for domain '$record_domain' has invalid TTL value"
            exit 1
        fi
        # Check number of entries for record
        record_entries="$(
            curl -H "Authorization: Bearer $api_key" -s \
            "https://api.hetzner.cloud/v1/zones/$record_domain/rrsets/$record_name/$record_type" | \
            jq '.rrset.records | length'
        )"
        if [ "$record_entries" -eq 0 ]; then
            log "Fatal error: $record_type record '$record_name' for domain '$record_domain' doesn't exist in Hetzner Console"
            exit 1
        fi
        if [ "$record_entries" -gt 1 ]; then
            log "Fatal error: $record_type record '$record_name' for domain '$record_domain' has more than one entry"
            exit 1
        fi
        # Check record interface connection
        case "$record_type" in
            'A') v='4';;
            'AAAA') v='6';;
        esac
        if ! curl "-$v" --interface "$record_interface" \
            -s -I 'https://ip.hetzner.com/' --connect-timeout 10 --max-time 10 -o /dev/null; then
            log "Fatal error: Network interface $record_interface has no IPv$v internet connection"
            exit 1
        fi
done <<EOF
$records
EOF
    log "All records are valid"
}

log "Starting hetzner_ddns $version"
test_dependencies
test_conf_file
load_and_test_api_key
load_records
test_interfaces
test_domains
test_records
log "Setup completed"
