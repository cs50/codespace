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
# Branch builds use cs50/cli:<arch> (main), canary uses cs50/cli:canary.
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

    # _help50_button discards command50's output, so stub it to see the payload
    check "the duck gets the command line and output as a transcript (or output alone without a command)"
    run "$IMAGE" bash --login -c '
        _alert() { :; }
        _help50_button() { printf "%s" "$2"; }
        test "$(_helpless "cat: x: No such file" "cat x")" = "$(printf "%s\n%s" "$ cat x" "cat: x: No such file")" &&
        test "$(_helpless "cat: x: No such file")" = "cat: x: No such file" &&
        test -z "$(_helpless "   " "cat x")"'

    check "root shells (Sysadmins profile) do not start help50"
    run --user root "$IMAGE" bash --login -c 'test -z "${HELP50:-}" && ! declare -F _helpful > /dev/null'
else
    skip "help50 checks: base image has no help50 (cs50/cli without #210)"
fi

check "help50 extension is packaged for installation"
run "$IMAGE" bash --login -c 'test -f /opt/cs50/extensions/help50-0.0.1.vsix && command -v command50 > /dev/null'

# The workflow strips settings from devcontainer.json before building, so read the committed copy when there is one
check "devcontainer.json declares the base image's JDK as the Java runtime (java.configuration.runtimes)"
repo="$(cd "$(dirname "$0")/.." && pwd)"
declared=$( (git -C "$repo" show HEAD:devcontainer.json 2> /dev/null || cat "$repo/devcontainer.json") | sed -nE 's/.*"name": *"JavaSE-([0-9]+)".*/\1/p' | head -n 1)
actual=$(run "$IMAGE" bash --login -c '/opt/jdk/bin/java -version 2>&1 | sed -nE "s/^openjdk version \"([0-9]+).*/\1/p"')
test -n "$declared" && test -n "$actual" && test "$declared" = "$actual" || { echo "devcontainer.json declares JavaSE-${declared:-?} but the image has JDK ${actual:-?}" >&2; false; }

# As in a codespace: postCreateCommand runs as ubuntu in the workspace folder (docker creates it root-owned, hence the chown)
check "postCreateCommand extracts glibc sources matching the installed libc, and gdb finds them when stopped in libc"
run --workdir /workspaces/smoke "$IMAGE" bash --login -c '
    test -f /usr/src/glibc/glibc.tar.gz || { echo "glibc.tar.gz missing" >&2; exit 1; }
    sudo chown ubuntu:ubuntu /workspaces/smoke && /opt/cs50/bin/postCreateCommand
    test ! -f /usr/src/glibc/glibc.tar.gz || { echo "postCreateCommand did not extract glibc.tar.gz" >&2; exit 1; }
    upstream=$(dpkg-query --showformat="\${Version}" --show libc6 | cut -d- -f1)
    grep -q "#define VERSION \"$upstream\"" /usr/src/glibc/version.h || { echo "glibc sources are not $upstream" >&2; exit 1; }
    printf "#include <stdio.h>\nint main(void) { puts(\"hi\"); return 0; }\n" > t.c && gcc -g t.c -o t
    gdb -batch -ex "break puts" -ex run -ex "info source" ./t 2>&1 | grep -q "^Located in /usr/src/glibc/" || { echo "gdb did not resolve libc source" >&2; exit 1; }
    env -u DEBUGINFOD_URLS gdb -q --interpreter=mi -batch -ex "break puts" -ex run -ex "info source" ./t 2>&1 | grep -q "Located in /usr/src/glibc/"'

echo "OK"
