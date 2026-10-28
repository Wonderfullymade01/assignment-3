#!/usr/bin/env bash
# scripts/lint.sh - Check required files exist and validate Bash scripts
# Usage: ./scripts/lint.sh
# Exit codes: 0 = all checks passed, 1 = one or more checks failed

set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

ERRORS=0

ok()  { echo "OK:   $1"; }
bad() { echo "FAIL: $1"; ERRORS=$((ERRORS+1)); }

echo "===== Lint ====="

# 1. Required files
REQUIRED_FILES=(
    README.md
    app/app.sh
    scripts/lint.sh
    scripts/build.sh
    tests/test.sh
    Dockerfile
    compose.yaml
    .dockerignore
    .github/workflows/ci.yml
)

for f in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$f" ]]; then
        ok "required file exists: $f"
    else
        bad "missing required file: $f"
    fi
done

# 2. Bash syntax and executable permission
for f in app/*.sh scripts/*.sh tests/*.sh; do
    [[ -f "$f" ]] || continue

    if bash -n "$f" 2>/dev/null; then
        ok "bash syntax: $f"
    else
        bad "bash syntax error: $f"
        bash -n "$f"
    fi

    if [[ -x "$f" ]]; then
        ok "executable: $f"
    else
        bad "not executable: $f"
    fi
done

# 3. ShellCheck (optional extra check)
if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck --severity=error app/*.sh scripts/*.sh tests/*.sh; then
        ok "shellcheck found no errors"
    else
        bad "shellcheck reported errors"
    fi
else
    echo "SKIP: shellcheck not installed"
fi

echo "================"
if (( ERRORS > 0 )); then
    echo "Lint failed with $ERRORS problem(s)"
    exit 1
fi

echo "Lint passed"
exit 0
