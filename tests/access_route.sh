#!/bin/sh
set -e
TEST_PORT=8204
. "$(dirname "$0")/harness.sh"
start_server

echo "--- pro before funding (expect 402) ---"
req "http://127.0.0.1:$TEST_PORT/pro"
echo "--- fund ---"
req -X POST "http://127.0.0.1:$TEST_PORT/fund"
echo "--- pro first request, funded (expect 200, charged once) ---"
req "http://127.0.0.1:$TEST_PORT/pro"
echo "--- pro second request, same cookie jar within ttl (expect 200, NOT re-charged) ---"
req "http://127.0.0.1:$TEST_PORT/pro"
