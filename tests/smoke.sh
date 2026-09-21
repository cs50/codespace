#!/bin/bash
# Smoke-tests a built cs50/codespace image. Usage: tests/smoke.sh [IMAGE]
# Each check has a timeout so that a regression that hangs the shell fails loudly.

set -o errexit -o errtrace -o nounset -o pipefail
step="startup"
trap 'echo "FAILED: $step" >&2' ERR

IMAGE="${1:-cs50/codespace}"
run() { timeout 60 docker run --rm --env CODESPACES=true --env RepositoryName=smoke "$@"; }
check() { step="$1"; echo "- $step"; }

echo "Checking $IMAGE"

check "non-interactive login shell exits (help50 must not start without a terminal)"
run "$IMAGE" bash --login -c 'echo ok' | grep -qx ok
echo true | run --interactive "$IMAGE" bash --login

check "help50 is inherited from cs50/cli and its hooks are overridden by codespace.sh"
run "$IMAGE" bash --login -c '
    test "$(type -P help50)" = /opt/cs50/bin/help50 &&
    test -f /etc/profile.d/help50.sh &&
    test "$WORKDIR" = /workspaces/smoke &&
    for f in _helped _helpful _helpless _help50_button _alert _ansi; do declare -F "$f" > /dev/null || { echo "missing $f" >&2; exit 1; }; done &&
    declare -f _help50_button | grep -q command50'

check "help50 extension is packaged for installation"
run "$IMAGE" bash --login -c 'test -f /opt/cs50/extensions/help50-0.0.1.vsix && command -v command50 > /dev/null'

check "hooks behave: advice is printed, empty output is ignored (no extension server needed)"
run "$IMAGE" bash --login -c '
    _helpful "Did you mean \`ls\`?" 2>&1 | grep -q "Did you mean" &&
    test -z "$(_helpless "" 2>&1)" &&
    test -z "$(_helpless "   " 2>&1)" &&
    _helpless "cat: x: No such file" 2>&1 | grep -q help50'

check "root shells (Sysadmins profile) do not start help50"
run --user root "$IMAGE" bash --login -c 'test -z "${HELP50:-}" && ! declare -F _helpful > /dev/null'

echo "OK"
