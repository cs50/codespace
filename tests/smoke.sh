#!/bin/bash
# Smoke-tests a built cs50/codespace image. Usage: tests/smoke.sh [IMAGE]
# Each check has a timeout so that a regression that hangs the shell fails loudly.

set -o errexit -o errtrace -o nounset -o pipefail
step="startup"
trap 'echo "FAILED: $step" >&2' ERR

IMAGE="${1:-cs50/codespace}"
run() { timeout 60 docker run --rm --env CODESPACES=true --env RepositoryName=smoke "$@"; }
check() { step="$1"; echo "- $step"; }
skip() { echo "- SKIPPED: $1"; }

echo "Checking $IMAGE"

check "login shells start without errors"
test -z "$(run "$IMAGE" bash --login -c 'true' 2>&1)"

check "non-interactive login shell exits (help50 must not start without a terminal)"
run "$IMAGE" bash --login -c 'echo ok' | grep -qx ok
echo true | run --interactive "$IMAGE" bash --login

# The rest applies once the cs50/cli base image carries help50 (cs50/cli#210).
# Branch builds use cs50/cli:amd64 (main), canary uses cs50/cli:canary.
if run "$IMAGE" bash --login -c 'test -f /etc/profile.d/help50.sh -a -f /opt/cs50/lib/cli'; then

    check "help50 is inherited from cs50/cli and its hooks are overridden by codespace.sh"
    run "$IMAGE" bash --login -c '
        test "$(type -P help50)" = /opt/cs50/bin/help50 &&
        test "$WORKDIR" = /workspaces/smoke &&
        for f in _helped _helpful _helpless _help50_button _alert _ansi; do declare -F "$f" > /dev/null || { echo "missing $f" >&2; exit 1; }; done &&
        declare -f _help50_button | grep -q command50'

    check "hooks behave: advice is printed, empty output is ignored (no extension server needed)"
    run "$IMAGE" bash --login -c '
        _helpful "Did you mean \`ls\`?" 2>&1 | grep -q "Did you mean" &&
        test -z "$(_helpless "" 2>&1)" &&
        test -z "$(_helpless "   " 2>&1)" &&
        _helpless "cat: x: No such file" 2>&1 | grep -q help50'

    check "root shells (Sysadmins profile) do not start help50"
    run --user root "$IMAGE" bash --login -c 'test -z "${HELP50:-}" && ! declare -F _helpful > /dev/null'
else
    skip "help50 checks: base image has no help50 (cs50/cli without #210)"
fi

check "help50 extension is packaged for installation"
run "$IMAGE" bash --login -c 'test -f /opt/cs50/extensions/help50-0.0.1.vsix && command -v command50 > /dev/null'

echo "OK"
