#!/bin/sh
set -e
TEST_PORT=8203
. "$(dirname "$0")/harness.sh"
start_server

echo "--- unfunded article (expect 402) ---"
req "http://127.0.0.1:$TEST_PORT/article/1"
echo "--- fund ---"
req -X POST "http://127.0.0.1:$TEST_PORT/fund"
echo "--- funded article (expect 200) ---"
req "http://127.0.0.1:$TEST_PORT/article/1"
echo "--- a second article view charges again (pay-per-view, expect balance to drop) ---"
req "http://127.0.0.1:$TEST_PORT/article/2"
