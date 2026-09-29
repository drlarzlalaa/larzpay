#!/bin/sh
set -e
TEST_PORT=8202
. "$(dirname "$0")/harness.sh"
start_server

echo "--- literal .. (--path-as-is, expect 403) ---"
curl -s -i --path-as-is "http://127.0.0.1:$TEST_PORT/static/../lib/app.lz" | sed -E 's/^Set-Cookie: .*/Set-Cookie: <redacted>/'
echo "--- percent-encoded %2e%2e over a raw socket (bypasses any client-side normalization, expect 403) ---"
# /dev/tcp is a bash-ism (not in dash/POSIX sh), and run_tests.sh runs
# every scenario with `sh` regardless of shebang - so this one line
# needs an explicit bash to get raw socket access.
bash -c "printf 'GET /static/%%2e%%2e/lib/app.lz HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n' | (exec 3<>/dev/tcp/127.0.0.1/$TEST_PORT; cat >&3; cat <&3)" | sed -E 's/^Set-Cookie: .*/Set-Cookie: <redacted>/'
