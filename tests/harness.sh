# Sourced by tests/*.sh - starts/stops examples/demo.lz on TEST_PORT
# (set by each test script before sourcing this) with a private cookie
# jar, and always cleans the server process up, even on failure.
COOKIE_JAR="$(mktemp)"
SERVER_PID=""
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cleanup() {
  if [ -n "$SERVER_PID" ]; then kill "$SERVER_PID" 2>/dev/null; wait "$SERVER_PID" 2>/dev/null; fi
  rm -f "$COOKIE_JAR"
}
trap cleanup EXIT INT TERM

start_server() {
  cd "$REPO_ROOT"
  LARZSCRIPT_PATH="$REPO_ROOT/lib" PORT="$TEST_PORT" larzscript examples/demo.lz >/tmp/larzpay_test_server_"$TEST_PORT".log 2>&1 &
  SERVER_PID=$!
  i=0
  while ! curl -s -o /dev/null "http://127.0.0.1:$TEST_PORT/"; do
    i=$((i + 1))
    if [ "$i" -ge 50 ]; then
      echo "server did not start on port $TEST_PORT"
      cat /tmp/larzpay_test_server_"$TEST_PORT".log
      exit 1
    fi
    sleep 0.1
  done
}

# curl with this test's cookie jar, headers included, Set-Cookie value
# redacted (a fresh uuid + hmac signature every run, so it can never
# match a fixed .expected file).
req() {
  curl -s -i -c "$COOKIE_JAR" -b "$COOKIE_JAR" "$@" | sed -E 's/^Set-Cookie: .*/Set-Cookie: <redacted>/'
}
