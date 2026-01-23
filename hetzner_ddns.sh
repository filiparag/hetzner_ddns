#!/bin/sh

program='hetzner_ddns'
version='1.0.1'
detach=0
verbose=0
cfg_file="/usr/local/etc/${program}.json"
pid_file="/var/run/${program}.pid"

# User-modifiable settings
conf_log_file=
conf_ip_check_cooldown=30
conf_request_timeout=10
conf_api_url='https://api.hetzner.cloud/v1'
conf_ip_url='https://ip.hetzner.com/'

log() {
    if test -r "$conf_log_file"; then
        printf '[%s] %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")" "$1" >> "$conf_log_file"
    fi
    if [ "$verbose" = 1 ]; then
        >&2 printf '[%s] %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")" "$1"
    fi
}

create_log_file() {
    if [ -z "$conf_log_file" ]; then
        return
    fi
    if install -m 644 /dev/null "$conf_log_file" 1>/dev/null 2>/dev/null; then
        log "Using log file '$conf_log_file'"
    else
        log "Warning: Unable to use log file '$conf_log_file'"
    fi
}

test_dependencies() {
    for d in awk curl cut getopts jq mkfifo mktemp netstat ifconfig sed sort uniq touch hostname cat tr wc; do
        if ! command -v "$d" 1> /dev/null 2> /dev/null; then
            echo "Error: Missing dependency '$d'"
            return 1
        fi
    done
}

parse_cli_args() {
    while getopts c:l:P:vVdh opt; do
        case "$opt" in
            c)
                cfg_file="$OPTARG";;
            l)
                conf_log_file="$OPTARG";;
            P)
                pid_file="$OPTARG";;
            v)
                display_version;
                exit 0;;
            V)
                verbose=1;;
            d)
                detach=1;;
            h)
                display_version;
                display_help;
                exit 0;;
            *)  exit 1;;
        esac
    done
    shift "$((OPTIND - 1))"
}

display_version() {
    echo "$program $version - Hetzner Dynamic DNS Daemon"
}

display_help() {
    echo '
Options:

    -c <file>   Use specified configuration file
    -l <file>   Use specified log file
    -P <file>   Use specified PID file when daemonized
    -V          Display all log messages to stderr
    -d          Detach from current shell and run as a daemon
    -h          Print help and exit
    -v          Print version and exit
'
echo '
Configuration:

    "settings": {
      "log_file": Path to a custom configuration file
      "ip_check_cooldown": Time between subsequent checks of interface'\''s IP address
      "request_timeout": Maximum duration of HTTP requests
      "api_url": URL of the Hetzner Console'\''s API
      "ip_url": URL of a service for retrieving external IP addresses
    }

    "defaults": {
      "type": Default record type (can be "A", "AAAA", or "A/AAAA")
      "interface": Default network interface name (auto-detect if unspecified)
      "ttl": Default TTL value in seconds (60 <= TTL <= 2147483647)
    }

    "zones": [
      {
        "domain": Domain name of a zone
        "records": [
          {
            "name": Name of the record (use @ for domain'\''s root)
            "type": Override of the default record type
            "ttl": Override of the default TTL
            "interface": Override of the default interface
          }
        ]
      }
    ]
'
echo '
Usage:

    Run on startup
        service hetzner_ddns enable

    Start
        service hetzner_ddns start

    Stop
        service hetzner_ddns stop

    Trigger update of all records
        service hetzner_ddns reload
'
}

test_cfg_file() {
    # Test if file exists
    if ! test -f "$cfg_file"; then
        log "Error: Configuration file '$cfg_file' not found"
        return 1
    fi
    if ! test -r "$cfg_file"; then
        log 'Error: Configuration file is not readable'
        return 1
    fi
    # Check version
    version_major="$(jq -r '.version | split(".") | .[0]' "$cfg_file")"
    if [ "$version_major" -ne 1 ] ; then
        log 'Error: Incompatible configuration file version'
        return 1
    fi
    log "Using configuration file '$cfg_file'"
}

test_pid_file() {
    if [ "$detach" = 1 ]; then
        # Test if file is writeable
        if ! touch "$pid_file" 1>/dev/null 2>/dev/null; then
            log "Error: Unable to open background process ID file '$pid_file'"
            return 1
        fi
    fi
}

check_daemon_already_running() {
    if [ "$detach" = 1 ]; then
        daemon_pid="$(cat "$pid_file")"
        if [ -n "$daemon_pid" ] && kill -0 "$daemon_pid" 1>/dev/null 2>/dev/null; then
            log "Error: Another daemon is already running as process $daemon_pid"
            return 1
        fi
    fi
}

load_and_test_api_key() {
    api_key="$(jq -r '.api_key' "$cfg_file")"
    if [ -z "$api_key" ] || [ "$api_key" = 'null' ]; then
        log 'Error: API key not provided'
        return 1
    fi
    if [ "$(printf '%s' "$api_key" | wc -m | tr -d '[:space:]')" != 64 ]; then
        log 'Error: Invalid API key format'
        return 1
    fi
    if [ "$(curl \
            --connect-timeout "$conf_request_timeout" --max-time "$conf_request_timeout" \
            -H "Authorization: Bearer $api_key" \
            -I -w "%{http_code}" \
            -s -o /dev/null \
            "$conf_api_url/zones")" != 200 ]; then
        log 'Error: Provided API key is unauthorized'
        return 1
    fi
    log 'Loaded valid API key'
}

load_settings() {
    if [ "$(jq -r '.settings' "$cfg_file")" != 'null' ]; then
        eval "$(jq -r '.settings | to_entries[] | "conf_\(.key)='\''\(.value|tostring)'\''"' "$cfg_file")"
        log 'Loaded user settings from configuration file'
    fi
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
    ' "$cfg_file")"
    if [ -z "$records" ]; then
        log 'No records found'
        return 1
    fi
}

display_records() {
    w_domain="$(printf 'DOMAIN\n%s' "$records" | cut -f1 | wc -L | tr -d '[:space:]')"
    w_name="$(printf 'NAME\n%s' "$records" | cut -f2 | wc -L | tr -d '[:space:]')"
    w_type="$(printf 'TYPE\n%s' "$records" | cut -f3 | wc -L | tr -d '[:space:]')"
    w_ttl="$(printf 'TTL\n%s' "$records" | cut -f4 | wc -L | tr -d '[:space:]')"
    w_interface="$(printf 'INTERFACE\n%s' "$records" | cut -f5 | wc -L | tr -d '[:space:]')"
    log "$(printf "+-%-${w_domain}s-+-%-${w_name}s-+-%-${w_type}s-+-%-${w_ttl}s-+-%-${w_interface}s-+\n" \
        | tr ' ' '-')"
    log "$(printf "| %-${w_domain}s | %-${w_name}s | %-${w_type}s | %-${w_ttl}s | %-${w_interface}s |\n" \
        "DOMAIN" "NAME" "TYPE" "TTL" "INTERFACE")"
    log "$(printf "+-%-${w_domain}s-+-%-${w_name}s-+-%-${w_type}s-+-%-${w_ttl}s-+-%-${w_interface}s-+\n" \
        | tr ' ' '-')"
    while IFS="$(printf '\t')" read -r record_domain record_name record_type record_ttl record_interface; do
        log "$(printf "| %-${w_domain}s | %-${w_name}s | %-${w_type}s | %${w_ttl}d | %-${w_interface}s |\n" \
            "$record_domain" "$record_name" "$record_type" "$record_ttl" "$record_interface")"
done <<EOF
$records
EOF
    log "$(printf "+-%-${w_domain}s-+-%-${w_name}s-+-%-${w_type}s-+-%-${w_ttl}s-+-%-${w_interface}s-+\n" \
        | tr ' ' '-')"
}

test_interfaces() {
    for i in $(printf '%s' "$records" | cut -f5 | sort | uniq); do
        if ! ifconfig "$i" >/dev/null 2>/dev/null; then
            log "Error: Missing network interface '$i'"
            return 1
        fi
    done
    log 'All network interfaces are working'
}

test_domains() {
    for d in $(printf '%s' "$records" | cut -f1 | sort | uniq -d); do
        if [ "$(curl \
                --connect-timeout "$conf_request_timeout" --max-time "$conf_request_timeout" \
                -H "Authorization: Bearer $api_key" \
                -I -w "%{http_code}" \
                -s -o /dev/null \
                "$conf_api_url/zones/$d/rrsets")" != 200 ]; then
            log "Error: Unable to access zone of domain '$d'"
            return 1
        fi
    done
    log 'All domain zones are accessible using provided API key'
}

test_records() {
    record_duplicates="$(printf '%s' "$records" | cut -f1-3 | sort | uniq -d)"
    # Check duplicate entries
    if [ -n "$record_duplicates" ]; then
        while IFS="$(printf '\t')" read -r record_domain record_name record_type; do
            log "Error: Multiple entries for record '$record_name' of type '$record_type' for domain '$record_domain'"
            return 1
done <<EOF
$record_duplicates
EOF
    fi
    while IFS="$(printf '\t')" read -r record_domain record_name record_type record_ttl record_interface; do
        # Check record type
        if [ "$record_type" != 'A' ] && [ "$record_type" != 'AAAA' ]; then
            log "Error: Record '$record_name' of type '$record_type' for domain '$record_domain' is not supported"
            return 1
        fi
        # Check record TTL
        if [ "$record_ttl" -lt 60 ]; then
            log "Error: $record_type record '$record_name' for domain '$record_domain' has too small TTL value"
            return 1
        elif [ "$record_ttl" -gt 2147483647 ]; then
            log "Error: $record_type record '$record_name' for domain '$record_domain' has large TTL value"
            return 1
        fi
        # Check number of entries for record
        record_entries="$(
            curl --connect-timeout "$conf_request_timeout" --max-time "$conf_request_timeout" \
                -H "Authorization: Bearer $api_key" -s \
                "$conf_api_url/zones/$record_domain/rrsets/$record_name/$record_type" | \
                jq '.rrset.records | length'
        )"
        if [ "$record_entries" -eq 0 ]; then
            log "Error: $record_type record '$record_name' for domain '$record_domain' doesn't exist in Hetzner Console"
            return 1
        elif [ "$record_entries" -gt 1 ]; then
            log "Error: $record_type record '$record_name' for domain '$record_domain' has more than one entry"
            return 1
        fi
        # Check record interface connection
        case "$record_type" in
            'A') v='4';;
            'AAAA') v='6';;
        esac
        if ! curl --connect-timeout "$conf_request_timeout" --max-time "$conf_request_timeout" \
                "-$v" --interface "$record_interface" -s -I "$conf_ip_url" -o /dev/null; then
            log "Warning: Network interface $record_interface has no IPv$v internet connection"
        fi
done <<EOF
$records
EOF
    log 'All records are valid:'
    display_records
}

create_service_state() {
    # Create directory
    state_dir="$(mktemp -d -t "${program}_XXXXXXXX")"
    # Register cleanup routine trigger
    trap cleanup_service_state TERM INT
    # Create event pipe
    event_pipe="$state_dir/event_pipe"
    if ! mkfifo -m 600 "$event_pipe"; then
        log "Error: Unable to create event pipe '$event_pipe'"
        return 1
    fi
    # PIDs of the service itself and event tickers
    long_processes="$state_dir/long_running_processes"
    # PIDs of short-lived updaters
    short_processes="$state_dir/temporary_processes"
    echo "$$" > "$long_processes"
    touch "$short_processes"
    # Dump all records
    echo "$records" > "$state_dir/records"
    # For each used interface create current IP values and last updated
    for i in $(echo "$records" | cut -f5 | sort | uniq); do
        echo > "$state_dir/if_${i}_ipv4_addr"
        echo > "$state_dir/if_${i}_ipv6_addr"
        echo '0' > "$state_dir/if_${i}_ipv4_last_updated"
        echo '0' > "$state_dir/if_${i}_ipv6_last_updated"
    done
    log "Service state directory '$state_dir' created"
}

trigger_manual_update() {
    if [ -p "$event_pipe" ]; then
        log 'Triggering update of all records'
        for t in $(printf '%s' "$records" | cut -f4 | sort | uniq); do
            echo "$t" > "$event_pipe"
        done
    else
        log 'Unable to trigger manual update'
    fi
}

cleanup_service_state() {
    log 'Cleanup started'
    # Kill all short-lived children processes
    for p in $(cat "$short_processes"); do
        kill -9 "$p" 1>/dev/null 2>/dev/null
        wait "$p" 1>/dev/null 2>/dev/null
    done
    # Kill all long-running children processes
    for p in $(tail -n +2 "$long_processes" | sort -r); do
        kill -9 "$p" 1>/dev/null 2>/dev/null
        wait "$p" 1>/dev/null 2>/dev/null
    done
    log 'Background tickers stopped'
    # Remove state directory
    rm -rf "$state_dir"
    log 'Service state directory removed'
    log 'Exiting cleanly'
    exit 0
}


clean_up_short_processes() {
    for p in $(cat "$short_processes"); do
        if kill -0 "$p" 2>/dev/null; then
            short_keep="$p $short_keep"
        fi
    done
    # Keep only still-running PIDs
    echo "$short_keep" | sed 's/ /\n/g' > "$short_processes"
}

event_ticker() {
    # Write TTL value to event pipe every TTL seconds
    exec 3> "$event_pipe"
    while :; do
        echo "$1" >&3
        sleep "$1"
    done
}

spawn_event_tickers() {
    for t in $(printf '%s' "$records" | cut -f4 | sort | uniq); do
        event_ticker "$t" &
        echo "$!" >> "$long_processes"
    done
    log 'Spawned background tickers'
}

start_event_loop() {
    log 'Started record update event loop'
    # Register manual update trigger
    trap trigger_manual_update USR1
    # Re-register cleanup if detached
    trap cleanup_service_state TERM INT
    while true; do
        while IFS= read -r ttl; do
            # Process the records whose TTL expired
            process_tick "$ttl"
            # Clean up temporary process list
            clean_up_short_processes
        done < "$event_pipe"
    done
}

update_interface_ip() {
    version="$1"
    interface="$2"
    last_updated="$(cat "$state_dir/if_${interface}_ipv${version}_last_updated")"
    now="$(date +%s)"
    if [ $((now - last_updated)) -lt "$conf_ip_check_cooldown" ]; then
        # Cooldown period not reached
        return
    fi
    old_value="$(cat "$state_dir/if_${interface}_ipv${version}_addr")"
    new_value="$(
        curl --connect-timeout "$conf_request_timeout" --max-time "$conf_request_timeout" \
            --interface "$interface" -"$version" "$conf_ip_url" 2>/dev/null
    )"
    if [ -z "$new_value" ]; then
        log "Warning: Could not fetch new IPv$version address for interface '$interface'"
        return 1
    fi
    echo "$now" > "$state_dir/if_${interface}_ipv${version}_last_updated"
    if [ "$old_value" != "$new_value" ]; then
        echo "$new_value" > "$state_dir/if_${interface}_ipv${version}_addr"
        log "Interface '$interface' has a new IPv$version address $new_value"
    else
        log "Interface '$interface' kept IPv$version address $new_value"
    fi
}

update_record() {
    domain=$1
    name=$2
    type=$3
    ttl=$4
    interface=$5
    log "Update time reached for $type record '$name' for domain '$domain'"
    current_rrset="$(
        curl -s -H "Authorization: Bearer $api_key" \
        "$conf_api_url/zones/$domain/rrsets/$name/$type"
    )"
    current_value="$(
        echo "$current_rrset" | \
        jq -r '.rrset.records[0].value'
    )"
    current_ttl="$(
        echo "$current_rrset" | \
        jq -r '.rrset.ttl'
    )"
    case "$type" in
        'A') version='4';;
        'AAAA') version='6';;
    esac
    expected_value="$(cat "$state_dir/if_${interface}_ipv${version}_addr")"
    if [ -z "$expected_value" ]; then
        log "Warning: Skipping update of $type record $name for domain $domain"
        return 1
    fi
    if [ -z "$current_value" ] || [ "$current_value" = 'null' ]; then
        log "Warning: Unable to fetch value of $type record $name for domain $domain"
        return 1
    fi
    if [ -z "$current_value" ] || [ "$current_value" = 'null' ]; then
        log "Warning: Failed reading IPv$version address of interface '$interface'"
        return 1
    fi
    if [ "$current_value" = "$expected_value" ]; then
        log "Keep existing value of $type record '$name' for domain '$domain'"
    else
        if curl -s -X POST -H "Authorization: Bearer $api_key" \
            -H "Content-Type: application/json" \
            -d "{
                \"records\": [
                    {
                        \"value\": \"$expected_value\",
                        \"comment\": \"Managed by $program on $(hostname)\"
                    }
                ]
            }" \
            "$conf_api_url/zones/$domain/rrsets/$name/$type/actions/set_records" >/dev/null; then
            log "Changed $type record '$name' for domain '$domain': $current_value => $expected_value"
        else
            log "Warning: Unable to update value of $type record '$name' for domain '$domain'"
        fi
    fi
    if [ "$current_ttl" = "$ttl" ]; then
        log "Keep existing TTL of $type record '$name' for domain '$domain'"
    else
        if curl -s -X POST -H "Authorization: Bearer $api_key" \
            -H "Content-Type: application/json" \
            -d "{
                \"ttl\": $ttl
            }" \
            "$conf_api_url/zones/$domain/rrsets/$name/$type/actions/change_ttl" >/dev/null; then
            log "Changed $type record '$name' for domain '$domain': TTL = $ttl"
        else
            log "Warning: Unable to update TTL of $type record '$name' for domain '$domain'"
        fi
    fi
}

process_tick() {
    ttl="$1"
    log "Check records with TTL value of $ttl seconds"
    # Update IPv4 addresses for all relevant interfaces
    updaters=
    for i in $(
        printf '%s' "$records" | \
        awk -v OFS='\t' -v ttl="$ttl" '$4 == ttl && $3 == "A" { print $5 }' \
        | sort | uniq); do
        update_interface_ip 4 "$i" &
        updaters="$! $updaters"
        echo "$!" >> "$short_processes"
    done
    # Update IPv6 addresses for all relevant interfaces
    for i in $(
        printf '%s' "$records" | \
        awk -v OFS='\t' -v ttl="$ttl" '$4 == ttl && $3 == "AAAA" { print $5 }' \
        | sort | uniq); do
        update_interface_ip 6 "$i" &
        updaters="$! $updaters"
        echo "$!" >> "$short_processes"
    done
    # Wait for IP updates to finish
    eval "wait $updaters"
    updaters=
    # Update all relevant records
    while IFS="$(printf '\t')" read -r record_domain record_name record_type record_ttl record_interface; do
        update_record "$record_domain" "$record_name" "$record_type" "$record_ttl" "$record_interface" &
        updaters="$! $updaters"
        echo "$!" >> "$short_processes"
done <<EOF
$(printf '%s' "$records" | awk  -v ttl="$ttl" '$4 == ttl')
EOF
    # Wait for record updates to finish
    eval "wait $updaters"
}

log "Starting $program $version"
{
    test_dependencies && \
    parse_cli_args "$@" && \
    test_pid_file && \
    check_daemon_already_running && \
    test_cfg_file && \
    load_settings && \
    create_log_file && \
    load_and_test_api_key && \
    load_records && \
    test_interfaces && \
    test_domains && \
    test_records && \
    create_service_state && \
    log 'Setup completed'
} ||
{
    log 'Setup failed';
    exit 1
}

if [ "$detach" = 1 ]; then
    {
        verbose=0
        spawn_event_tickers && \
        start_event_loop
        cleanup_service_state
    } 1>/dev/null 2>/dev/null &
    daemon_pid="$!"
    printf '%d' "$daemon_pid" > "$pid_file"
    log "Registering daemon in $pid_file"
    log "Detaching $program to background as process $daemon_pid"
else
    spawn_event_tickers && \
    start_event_loop
    cleanup_service_state
fi
