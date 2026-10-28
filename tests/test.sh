#!/usr/bin/env bash
# tests/test.sh - Automated tests for app/app.sh
# Usage: ./tests/test.sh
# Exit codes: 0 = all tests passed, 1 = one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$SCRIPT_DIR/../app/app.sh"

PASS=0
FAIL=0

# run_case <name> <expected exit code> <text expected in output> <app arguments...>
run_case() {
    local name="$1" expected_code="$2" expected_text="$3"
    shift 3

    local output code
    output=$("$APP" "$@" 2>&1)
    code=$?

    if [[ $code -eq $expected_code ]] && grep -qi -- "$expected_text" <<< "$output"; then
        echo "PASS: $name"
        PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected exit $expected_code with '$expected_text', got exit $code)"
        echo "$output" | sed 's/^/    /'
        FAIL=$((FAIL+1))
    fi
}

echo "======================================"
echo " app.sh test suite"
echo "======================================"

# help and system-info
run_case "help shows usage"                    0 "Usage"                 help
run_case "system-info shows hostname"          0 "Hostname"              system-info
run_case "system-info shows kernel version"    0 "Kernel"                system-info

# invalid commands
run_case "missing command returns 2"           2 "no command"
run_case "invalid command returns 2"           2 "unknown command"       invalid-command

# check-host
run_case "check-host without host returns 2"   2 "missing host"          check-host
run_case "check-host resolves localhost"       0 "Resolved IP"           check-host localhost
run_case "check-host rejects invalid host"     2 "invalid hostname"      check-host "bad host!"

# check-port validation
run_case "check-port without host returns 2"   2 "missing host"          check-port
run_case "check-port without port returns 2"   2 "missing port"          check-port localhost
run_case "check-port rejects non-numeric port" 2 "must be a number"      check-port localhost abc
run_case "check-port rejects port 0"           2 "between 1 and 65535"   check-port localhost 0
run_case "check-port rejects port 65536"       2 "between 1 and 65535"   check-port localhost 65536

echo
echo "======================================"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "======================================"

[[ $FAIL -eq 0 ]]
