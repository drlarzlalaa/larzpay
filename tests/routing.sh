#!/bin/sh
set -e
TEST_PORT=8201
. "$(dirname "$0")/harness.sh"
start_server

echo "--- GET / ---"
req "http://127.0.0.1:$TEST_PORT/"
echo "--- GET /static/hello.txt ---"
req "http://127.0.0.1:$TEST_PORT/static/hello.txt"
echo "--- GET /nope (404) ---"
req "http://127.0.0.1:$TEST_PORT/nope"
