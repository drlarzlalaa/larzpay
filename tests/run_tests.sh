#!/bin/sh
# Runs each tests/*.sh scenario and diffs its combined output against
# tests/<name>.expected. Same discipline as larz-cronlint/larzscript-superpowers.
set -e
cd "$(dirname "$0")/.."

pass=0; fail=0
for t in tests/*.sh; do
  case "$t" in tests/run_tests.sh|tests/harness.sh) continue ;; esac
  exp="${t%.sh}.expected"
  got="$(sh "$t" 2>&1 || true)"
  if [ "$got" = "$(cat "$exp")" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1)); echo "FAIL $t"; echo "--- expected ---"; cat "$exp"; echo "--- got ---"; echo "$got"
  fi
done
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
