#!/bin/sh
set -e
TEST_PORT=8205
. "$(dirname "$0")/harness.sh"
start_server

# Regression test for the exact bug this project works around
# (github.com/larz-scripter/larzscript issue #37): two dynamically
# created wallets from the same factory function must stay
# independent. Customer A funds and pays; customer B (a distinct
# cookie jar / customer id, never funded) must still be refused.
JAR_A="$(mktemp)"
JAR_B="$(mktemp)"
trap 'rm -f "$JAR_A" "$JAR_B"; cleanup' EXIT INT TERM

get_a() { curl -s -i -c "$JAR_A" -b "$JAR_A" "$@" | sed -E 's/^Set-Cookie: .*/Set-Cookie: <redacted>/'; }
get_b() { curl -s -i -c "$JAR_B" -b "$JAR_B" "$@" | sed -E 's/^Set-Cookie: .*/Set-Cookie: <redacted>/'; }

echo "--- customer A funds ---"
get_a -X POST "http://127.0.0.1:$TEST_PORT/fund"
echo "--- customer A reads the paid article (expect 200) ---"
get_a "http://127.0.0.1:$TEST_PORT/article/1"
echo "--- customer B, never funded, same article (expect 402 - NOT leaked from A) ---"
get_b "http://127.0.0.1:$TEST_PORT/article/1"
