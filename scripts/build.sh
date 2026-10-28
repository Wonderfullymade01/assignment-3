#!/usr/bin/env bash
# scripts/build.sh - Build the Docker image and run smoke tests
# Usage: ./scripts/build.sh
# Exit codes: 0 = build and smoke tests passed, 1 = build or a smoke test failed

set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

IMAGE="${IMAGE:-devops-tool}"
FAILED=0

# smoke <name> <expected exit code> <container arguments...>
smoke() {
    local name="$1" expected_code="$2"
    shift 2

    local code
    docker run --rm "$IMAGE" "$@" >/dev/null 2>&1
    code=$?

    if [[ $code -eq $expected_code ]]; then
        echo "PASS: $name (exit $code)"
    else
        echo "FAIL: $name (expected exit $expected_code, got $code)"
        FAILED=1
    fi
}

echo "===== Building image '$IMAGE' ====="
if ! docker build -t "$IMAGE" .; then
    echo "FAIL: docker build failed"
    exit 1
fi

echo
echo "===== Smoke tests ====="
smoke "help works"                      0 help
smoke "default command shows help"      0
smoke "system-info works"               0 system-info
smoke "check-host localhost works"      0 check-host localhost
smoke "invalid command returns 2"       2 invalid-command
smoke "non-numeric port returns 2"      2 check-port localhost abc

echo "======================="
if (( FAILED )); then
    echo "Smoke tests failed"
    exit 1
fi

echo "Build and smoke tests passed"
exit 0
