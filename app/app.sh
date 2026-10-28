#!/usr/bin/env bash
# app.sh - DevOps diagnostic tool
# Usage: ./app/app.sh <command> [arguments]
# Exit codes: 0 = success, 1 = operational/runtime failure, 2 = invalid command or input

set -u

usage() {
    cat <<EOF
Usage: app.sh <command> [arguments]

Commands:
  system-info               Show system information
  check-host <host>         Resolve a hostname or IP address
  check-port <host> <port>  Check TCP connectivity to a port (1-65535)
  help                      Show this help message

Exit codes:
  0  success
  1  operational/runtime failure
  2  invalid command or input
EOF
}

error() {
    echo "Error: $1" >&2
}

# Hostnames/IPs: letters, digits, dots and hyphens; must not start with a hyphen
validate_host() {
    local host="$1"
    if [[ -z "$host" || ${#host} -gt 253 || ! "$host" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]]; then
        error "invalid hostname or IP address '$host'"
        return 2
    fi
}

# Ports: whole number from 1 to 65535
validate_port() {
    local port="$1"
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        error "port must be a number, got '$port'"
        return 2
    fi
    if (( 10#$port < 1 || 10#$port > 65535 )); then
        error "port must be between 1 and 65535, got '$port'"
        return 2
    fi
}

cmd_system_info() {
    if [[ $# -gt 0 ]]; then
        error "'system-info' takes no arguments"
        return 2
    fi

    if [[ ! -r /proc/uptime || ! -r /proc/meminfo ]]; then
        error "cannot read /proc system information"
        return 1
    fi

    local os="unknown"
    if [[ -r /etc/os-release ]]; then
        os=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
    fi

    local up_seconds up_hours up_minutes
    up_seconds=$(cut -d. -f1 /proc/uptime)
    up_hours=$(( up_seconds / 3600 ))
    up_minutes=$(( (up_seconds % 3600) / 60 ))

    local cpu cores
    cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
    cores=$(nproc)

    local mem_total mem_avail mem_used
    mem_total=$(awk '/^MemTotal:/ {print int($2/1024)}' /proc/meminfo)
    mem_avail=$(awk '/^MemAvailable:/ {print int($2/1024)}' /proc/meminfo)
    mem_used=$(( mem_total - mem_avail ))

    echo "===== System Information ====="
    echo "Hostname:          $(hostname)"
    echo "Current user:      $(whoami)"
    echo "Date/time:         $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Operating system:  ${os:-unknown}"
    echo "Kernel version:    $(uname -r)"
    echo "Uptime:            ${up_hours}h ${up_minutes}m"
    echo "CPU:               ${cpu:-unknown} (${cores} cores)"
    echo "Memory:            ${mem_used} MB used / ${mem_total} MB total"
    echo "=============================="
}

cmd_check_host() {
    if [[ $# -lt 1 ]]; then
        error "missing host"
        echo "Usage: app.sh check-host <host>" >&2
        return 2
    fi
    if [[ $# -gt 1 ]]; then
        error "'check-host' takes exactly one host"
        return 2
    fi

    local host="$1"
    validate_host "$host" || return 2

    local ip
    ip=$(getent hosts "$host" | awk '{print $1; exit}')
    if [[ -z "$ip" ]]; then
        echo "Host '$host': could not be resolved"
        return 1
    fi

    echo "Host:        $host"
    echo "Resolved IP: $ip"
}

cmd_check_port() {
    if [[ $# -lt 1 ]]; then
        error "missing host"
        echo "Usage: app.sh check-port <host> <port>" >&2
        return 2
    fi
    if [[ $# -lt 2 ]]; then
        error "missing port"
        echo "Usage: app.sh check-port <host> <port>" >&2
        return 2
    fi
    if [[ $# -gt 2 ]]; then
        error "'check-port' takes exactly a host and a port"
        return 2
    fi

    local host="$1"
    validate_host "$host" || return 2
    validate_port "$2" || return 2
    local port=$((10#$2))

    # Bash's /dev/tcp opens a TCP connection; timeout stops it hanging
    if timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        echo "TCP $host:$port is OPEN"
    else
        echo "TCP $host:$port is CLOSED or unreachable"
        return 1
    fi
}

main() {
    if [[ $# -lt 1 ]]; then
        error "no command given"
        usage >&2
        return 2
    fi

    local command="$1"
    shift

    case "$command" in
        system-info)     cmd_system_info "$@" ;;
        check-host)      cmd_check_host "$@" ;;
        check-port)      cmd_check_port "$@" ;;
        help|-h|--help)  usage ;;
        *)
            error "unknown command '$command'"
            usage >&2
            return 2
            ;;
    esac
}

main "$@"
exit $?
